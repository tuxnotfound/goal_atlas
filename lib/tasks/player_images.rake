# Rake tasks for bulk-scouting and curating player portrait images from
# Wikimedia Commons (see app/services/wikimedia_portrait_scout.rb).
#
# Examples:
#   bundle exec rake 'player_images:fetch_for[lionel-messi]'
#   bundle exec rake 'player_images:fetch_for_tournament[2022]'
#   bundle exec rake player_images:fetch_missing
#   bundle exec rake player_images:fetch_all

namespace :player_images do
  desc "Scout Commons portraits for a single Player (by slug or name)."
  task :fetch_for, [:identifier] => :environment do |_t, args|
    abort "Usage: rake 'player_images:fetch_for[<slug-or-name>]'" unless args[:identifier]
    player = find_player(args[:identifier])
    abort "Player not found: #{args[:identifier]}" unless player
    fetch_for_player(player)
  end

  desc "Scout Commons portraits for every Player who appeared in a tournament. Usage: rake 'player_images:fetch_for_tournament[2022]'"
  task :fetch_for_tournament, [:year] => :environment do |_t, args|
    abort "Usage: rake 'player_images:fetch_for_tournament[<year>]'" unless args[:year]
    tournament = Tournament.find_by!(year: args[:year].to_i)
    players = players_in_tournament(tournament)
    puts "#{players.size} players appeared in #{tournament.name}; scouting all of them..."

    players.each_with_index do |player, idx|
      print "[#{idx + 1}/#{players.size}] "
      fetch_for_player(player)
      sleep 0.3
    end
  end

  desc "Scout Commons portraits for every Player in the DB."
  task fetch_all: :environment do
    players = Player.kept.order(:name).to_a
    players.each_with_index do |player, idx|
      print "[#{idx + 1}/#{players.size}] "
      fetch_for_player(player)
      sleep 0.3
    end
  end

  desc "Scout Commons portraits only for Players that have no image yet."
  task fetch_missing: :environment do
    players = Player.kept.left_outer_joins(:player_images).where(player_images: { id: nil }).order(:name).to_a
    puts "#{players.size} players missing portraits; scouting..."

    players.each_with_index do |player, idx|
      print "[#{idx + 1}/#{players.size}] "
      fetch_for_player(player)
      sleep 0.3
    end
  end

  desc "Generate stylized portraits for all scorers in a tournament year, skipping anyone who already has one. Usage: rake 'player_images:stylize_scorers[2022]'"
  task :stylize_scorers, [:year] => :environment do |_t, args|
    abort "Usage: rake 'player_images:stylize_scorers[<year>]'" unless args[:year]
    tournament = Tournament.find_by!(year: args[:year].to_i)

    scorers = Player.kept
                .joins(goals: :match)
                .where(matches: { tournament_id: tournament.id })
                .distinct
                .left_outer_joins(:stylized_portraits)
                .where(stylized_portraits: { id: nil })
                .order(:name)
                .to_a

    total = scorers.size
    puts "Stylizing #{total} scorers from #{tournament.name} (skipping those already styled)..."

    ok = 0
    fail = 0
    scorers.each_with_index do |player, idx|
      unless player.portrait_image
        puts "[#{idx + 1}/#{total}] #{player.name} — no portrait_image, skipping"
        fail += 1
        next
      end

      begin
        portrait = ::PortraitStylizer.new(player, logger: Rails.logger).generate!
        ok += 1
        puts "[#{idx + 1}/#{total}] #{player.name} — stylized id=#{portrait.id}"
      rescue => e
        fail += 1
        puts "[#{idx + 1}/#{total}] #{player.name} — ERROR: #{e.class}: #{e.message.to_s.truncate(160)}"
      end

      # Brief pause to be polite to OpenAI's rate limits.
      sleep 1
    end

    puts "Done — ok=#{ok} fail=#{fail} of #{total}."
  end

  desc "Score every player's images and tag the highest-scoring one as is_portrait. Optional [skip_year] excludes players who appeared in that tournament (useful when a stylize batch is running on them). Usage: rake 'player_images:tag_portraits[2022]'"
  task :tag_portraits, [:skip_year] => :environment do |_t, args|
    scope = Player.kept.joins(:player_images).distinct

    if args[:skip_year]
      skip_t = Tournament.find_by(year: args[:skip_year].to_i)
      if skip_t
        scorer_ids = Goal.kept.joins(:match).where(matches: { tournament_id: skip_t.id }).distinct.pluck(:player_id)
        kicker_ids = ShootoutKick.kept.joins(:match).where(matches: { tournament_id: skip_t.id }).distinct.pluck(:player_id)
        award_ids  = TournamentAward.where(tournament: skip_t).pluck(:player_id)
        skip_ids   = (scorer_ids + kicker_ids + award_ids).compact.uniq
        scope = scope.where.not(id: skip_ids)
        puts "Skipping #{skip_ids.size} players who appeared in #{skip_t.name}"
      else
        puts "No tournament found for year #{args[:skip_year]}; processing all players."
      end
    end

    players = scope.order(:name).to_a
    total = players.size
    puts "Tagging portraits across #{total} players..."

    promoted = 0
    unchanged = 0
    skipped = 0

    players.each_with_index do |player, idx|
      scorable = player.player_images.kept.active.to_a
      if scorable.empty?
        skipped += 1
        next
      end

      scorer = PortraitScorer.new(player)
      best = scorable.max_by { |img| scorer.score_image(img) }

      if best.is_portrait?
        unchanged += 1
        next
      end

      PlayerImage.transaction do
        player.player_images.where(is_portrait: true).where.not(id: best.id).update_all(is_portrait: false)
        best.update!(is_portrait: true)
      end
      promoted += 1
      puts "[#{idx + 1}/#{total}] #{player.name} — image_id=#{best.id} tagged as portrait"
    end

    puts "Done — promoted=#{promoted} unchanged=#{unchanged} skipped=#{skipped} of #{total}."
  end

  desc "Re-query Commons for existing PlayerImage rows to populate image_width/height/commons_categories."
  task backfill_commons_metadata: :environment do
    scope = PlayerImage.kept
      .where("url LIKE ?", "https://upload.wikimedia.org/wikipedia/commons/%")
      .where("url NOT LIKE ?", "%/thumb/%")
      .where("image_width IS NULL OR commons_categories = '{}'")
      .includes(:player)
      .order(:id)

    total = scope.count
    if total.zero?
      puts "No PlayerImage rows need backfilling. Done."
      next
    end

    puts "Backfilling Commons metadata on #{total} player images..."
    scout = WikimediaPortraitScout.new(logger: Rails.logger)
    updated = 0
    missing = 0
    errored = 0

    scope.find_each.with_index do |img, idx|
      file_name = commons_filename_from_url(img.url)
      info = scout.file_info(file_name)

      if info.nil?
        missing += 1
        puts "[#{idx + 1}/#{total}] #{img.player.name} (image_id=#{img.id}) — Commons returned nothing"
        next
      end

      img.update!(
        image_width:        info[:width],
        image_height:       info[:height],
        commons_categories: info[:categories] || []
      )
      updated += 1
      puts "[#{idx + 1}/#{total}] #{img.player.name} (image_id=#{img.id}) — w=#{info[:width]} h=#{info[:height]} cats=#{(info[:categories] || []).size}"
      sleep 0.3
    rescue => e
      errored += 1
      puts "[#{idx + 1}/#{total}] image_id=#{img.id} ERROR: #{e.class}: #{e.message}"
    end

    puts "Backfill done — updated=#{updated} missing=#{missing} errored=#{errored} of #{total}."
  end

  def commons_filename_from_url(url)
    CGI.unescape(File.basename(URI.parse(url).path))
  end

  def find_player(identifier)
    Player.friendly.find(identifier) rescue Player.find_by(name: identifier)
  end

  def players_in_tournament(tournament)
    scorer_ids = Goal.kept.joins(:match).where(matches: { tournament_id: tournament.id }).distinct.pluck(:player_id)
    kicker_ids = ShootoutKick.kept.joins(:match).where(matches: { tournament_id: tournament.id }).distinct.pluck(:player_id)
    award_ids  = TournamentAward.where(tournament: tournament).pluck(:player_id)
    Player.kept.where(id: (scorer_ids + kicker_ids + award_ids).uniq).order(:name).to_a
  end

  def fetch_for_player(player)
    result = PlayerImageImporter.new(player, logger: Rails.logger).import!
    if result.candidates.empty?
      puts "#{player.name} — no portraits found"
    else
      puts "#{player.name} — #{result.candidates.size} candidate(s), #{result.added.size} new, #{result.tournament_tags} tournament tag(s)"
    end
  rescue => e
    puts "#{player.name} — ERROR: #{e.class}: #{e.message}"
  end
end
