# Rake tasks for video-link curation via YouTube Data API.
# Requires YOUTUBE_API_KEY env var (see app/services/video_link_scout.rb).
#
# Examples:
#   bundle exec rake video_links:suggest_for_goal[lionel-messi-vs-france-2022-23]
#   bundle exec rake video_links:suggest_for_match[argentina-vs-france-2022]
#   bundle exec rake video_links:add_for_goal[lionel-messi-vs-france-2022-23,"https://youtu.be/...",youtube_official]
#
# (Quote the URL when it contains query strings.)

namespace :video_links do
  desc "Suggest YouTube video links for a Goal (by slug). Usage: rake video_links:suggest_for_goal[<slug>]"
  task :suggest_for_goal, [:slug] => :environment do |_t, args|
    abort "Usage: rake video_links:suggest_for_goal[<goal-slug>]" unless args[:slug]

    goal = Goal.friendly.find(args[:slug])
    puts "Goal: #{goal.minute}' #{goal.player.name} (#{goal.scoring_team.fifa_code} vs #{goal.opponent_team.fifa_code})"
    puts "Match: #{goal.match.home_team.name} #{goal.match.home_score}-#{goal.match.away_score} #{goal.match.away_team.name} (#{goal.match.date})"
    puts ""

    print_suggestions(VideoLinkScout.new.suggest_for_goal(goal))
  end

  desc "Suggest YouTube video links for a Match (by slug). Usage: rake video_links:suggest_for_match[<slug>]"
  task :suggest_for_match, [:slug] => :environment do |_t, args|
    abort "Usage: rake video_links:suggest_for_match[<match-slug>]" unless args[:slug]

    match = Match.friendly.find(args[:slug])
    puts "Match: #{match.home_team.name} #{match.home_score}-#{match.away_score} #{match.away_team.name} (#{match.date}, #{match.stage.humanize})"
    puts ""

    print_suggestions(VideoLinkScout.new.suggest_for_match(match))
  end

  desc "Attach a video link to a Goal. Usage: rake video_links:add_for_goal[<slug>,<url>,<source>]"
  task :add_for_goal, [:slug, :url, :source] => :environment do |_t, args|
    abort "Usage: rake video_links:add_for_goal[<slug>,<url>,<source>]" unless args[:slug] && args[:url] && args[:source]

    goal = Goal.friendly.find(args[:slug])
    link = goal.video_links.find_or_create_by!(url: args[:url]) do |l|
      l.source     = args[:source]
      l.confidence = :likely
      l.language   = "en"
      l.is_active  = true
    end
    puts "✓ Linked #{goal.slug} → #{link.url} (#{link.source})"
  end

  desc "Attach a video link to a Match. Usage: rake video_links:add_for_match[<slug>,<url>,<source>]"
  task :add_for_match, [:slug, :url, :source] => :environment do |_t, args|
    abort "Usage: rake video_links:add_for_match[<slug>,<url>,<source>]" unless args[:slug] && args[:url] && args[:source]

    match = Match.friendly.find(args[:slug])
    link = match.video_links.find_or_create_by!(url: args[:url]) do |l|
      l.source     = args[:source]
      l.confidence = :likely
      l.language   = "en"
      l.is_active  = true
    end
    puts "✓ Linked #{match.slug} → #{link.url} (#{link.source})"
  end

  def print_suggestions(results)
    if results.empty?
      puts "No results."
      return
    end

    results.each_with_index do |r, i|
      puts "[#{i + 1}] #{r[:title]}"
      puts "    #{r[:url]}"
      puts "    Channel: #{r[:channel]} · Published: #{r[:published_at]}"
      puts ""
    end
    puts "Query used: #{results.first[:query]}"
  end
end
