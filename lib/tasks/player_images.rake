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
