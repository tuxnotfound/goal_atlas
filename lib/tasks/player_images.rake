# Rake tasks for bulk-scouting and curating player portrait images from
# Wikimedia Commons (see app/services/wikimedia_portrait_scout.rb).
#
# Examples:
#   bundle exec rake player_images:fetch_for[lionel-messi]
#   bundle exec rake player_images:fetch_all
#   bundle exec rake player_images:fetch_missing

namespace :player_images do
  desc "Scout Commons portraits for a single Player (by slug or name)."
  task :fetch_for, [:identifier] => :environment do |_t, args|
    abort "Usage: rake player_images:fetch_for[<slug-or-name>]" unless args[:identifier]
    player = find_player(args[:identifier])
    abort "Player not found: #{args[:identifier]}" unless player

    scout = WikimediaPortraitScout.new(logger: Rails.logger)
    fetch_for_player(player, scout)
  end

  desc "Scout Commons portraits for every Player in the DB."
  task fetch_all: :environment do
    scout = WikimediaPortraitScout.new(logger: Rails.logger)
    Player.kept.order(:name).each_with_index do |player, idx|
      print "[#{idx + 1}/#{Player.kept.count}] "
      fetch_for_player(player, scout)
      sleep 0.5 # be polite to Wikimedia
    end
  end

  desc "Scout Commons portraits only for Players that have no image yet."
  task fetch_missing: :environment do
    scout = WikimediaPortraitScout.new(logger: Rails.logger)
    players = Player.kept.left_outer_joins(:player_images).where(player_images: { id: nil }).order(:name)
    total = players.count
    players.each_with_index do |player, idx|
      print "[#{idx + 1}/#{total}] "
      fetch_for_player(player, scout)
      sleep 0.5
    end
  end

  def find_player(identifier)
    Player.friendly.find(identifier) rescue Player.find_by(name: identifier)
  end

  def fetch_for_player(player, scout)
    candidates = scout.search(player_name: player.name, max: 8)
    if candidates.empty?
      puts "#{player.name} — no candidates"
      return
    end

    created = 0
    candidates.each_with_index do |c, i|
      image = player.player_images.find_or_initialize_by(url: c.url)
      next unless image.new_record? # don't overwrite admin-edited rows

      image.assign_attributes(
        source_url:    c.source_url,
        thumbnail_url: c.thumbnail_url,
        license:       c.license,
        license_url:   c.license_url,
        author:        c.author,
        description:   c.description,
        position:      i,
        is_default:    (i == 0 && player.player_images.default.none?),
        is_active:     true,
        fetched_at:    Time.current
      )
      image.save!
      created += 1
    end
    puts "#{player.name} — #{candidates.size} candidates (#{created} new)"
  rescue => e
    puts "#{player.name} — ERROR: #{e.class}: #{e.message}"
  end
end
