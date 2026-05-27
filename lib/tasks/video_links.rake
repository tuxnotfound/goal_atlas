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

  # YouTube enforces ~10 search calls/min/project. 7s between calls keeps
  # us comfortably under that ceiling without burning user wall-time.
  AUTOFETCH_SLEEP_SECONDS = 7

  desc "Auto-attach FIFA/broadcaster YouTube highlight reels to MATCHES in a tournament that lack any video link. Usage: rake video_links:autofetch_matches[<year>,<limit>]"
  task :autofetch_matches, [:year, :limit] => :environment do |_t, args|
    abort "Usage: rake video_links:autofetch_matches[<year>,<limit?>]" unless args[:year]
    limit = args[:limit].to_i
    limit = nil if limit.zero?

    tournament = Tournament.find_by!(year: args[:year].to_i)
    scope = tournament.matches.left_outer_joins(:video_links)
                       .where(video_links: { id: nil })
                       .order(:match_number)
    scope = scope.limit(limit) if limit
    matches = scope.to_a

    puts "Tournament: #{tournament.year} #{tournament.name}"
    puts "Matches without any video_link: #{matches.size}#{limit ? " (limited)" : ""}"
    puts "Estimated YouTube quota: #{matches.size * 100}-#{matches.size * 200} units"
    puts "Throttling: #{AUTOFETCH_SLEEP_SECONDS}s between API calls (~#{matches.size * AUTOFETCH_SLEEP_SECONDS}s minimum)"
    puts ""

    scout = VideoLinkScout.new
    attached = 0
    skipped  = 0

    matches.each_with_index do |m, idx|
      label = "M#{m.match_number} #{m.home_team.fifa_code} v #{m.away_team.fifa_code}"
      result = with_rate_limit_retry { scout.find_best_for_match(m) }
      if result.nil?
        puts "#{label}: no relevant result"
        skipped += 1
      else
        link = m.video_links.find_or_initialize_by(url: result[:url])
        was_new = link.new_record?
        link.assign_attributes(source: result[:source], confidence: :unverified, language: "en", is_active: true, embed_allowed: result.fetch(:embed_allowed, false))
        link.save!
        puts "#{label}: → #{result[:url]} (#{result[:source]}) #{was_new ? "[NEW]" : "[exists]"}"
        attached += 1 if was_new
      end
      sleep AUTOFETCH_SLEEP_SECONDS unless idx == matches.size - 1
    end

    puts ""
    puts "Attached: #{attached} new match-level link(s). Skipped: #{skipped}."
  end

  desc "Auto-attach FIFA/broadcaster YouTube clips to GOALS in a tournament that lack any video link. Usage: rake video_links:autofetch_goals[<year>,<limit>]"
  task :autofetch_goals, [:year, :limit] => :environment do |_t, args|
    abort "Usage: rake video_links:autofetch_goals[<year>,<limit?>]" unless args[:year]
    limit = args[:limit].to_i
    limit = nil if limit.zero?

    tournament = Tournament.find_by!(year: args[:year].to_i)
    scope = Goal.joins(:match).where(matches: { tournament_id: tournament.id })
                .left_outer_joins(:video_links).where(video_links: { id: nil })
                .order("matches.match_number, goals.minute")
    scope = scope.limit(limit) if limit
    goals = scope.to_a

    puts "Tournament: #{tournament.year} #{tournament.name}"
    puts "Goals without any video_link: #{goals.size}#{limit ? " (limited)" : ""}"
    puts "Estimated YouTube quota: #{goals.size * 100}-#{goals.size * 200} units"
    puts "Throttling: #{AUTOFETCH_SLEEP_SECONDS}s between API calls (~#{goals.size * AUTOFETCH_SLEEP_SECONDS}s minimum)"
    puts ""

    scout = VideoLinkScout.new
    attached = 0
    skipped  = 0

    begin
      goals.each_with_index do |g, idx|
        label = "#{g.minute}' #{g.player.name} (#{g.scoring_team.fifa_code} v #{g.opponent_team.fifa_code})"
        result = with_rate_limit_retry { scout.find_best_for_goal(g) }
        if result.nil?
          puts "#{label}: no relevant result"
          skipped += 1
        else
          link = g.video_links.find_or_initialize_by(url: result[:url])
          was_new = link.new_record?
          link.assign_attributes(source: result[:source], confidence: :unverified, language: "en", is_active: true, embed_allowed: result.fetch(:embed_allowed, false))
          link.save!
          puts "#{label}: → #{result[:url]} (#{result[:source]}) #{was_new ? "[NEW]" : "[exists]"}"
          attached += 1 if was_new
        end
        sleep AUTOFETCH_SLEEP_SECONDS unless idx == goals.size - 1
      end
    rescue VideoLinkScout::DailyQuotaExhausted => e
      puts ""
      puts "Stopping early: #{e.message}."
      puts "Re-run the same task tomorrow (after the YouTube quota resets) to continue."
    end

    puts ""
    puts "Attached: #{attached} new goal-level link(s). Skipped: #{skipped}."
  end

  desc "Scout archive.org for match-level video for every match in a tournament that lacks a video link. Usage: rake video_links:scout_archive_org[<year>]"
  task :scout_archive_org, [:year, :limit] => :environment do |_t, args|
    abort "Usage: rake video_links:scout_archive_org[<year>,<limit?>]" unless args[:year]

    tournament = Tournament.find_by!(year: args[:year].to_i)
    scope = tournament.matches.left_outer_joins(:video_links)
                       .where(video_links: { id: nil })
                       .order(:match_number)
    limit = args[:limit].to_i
    scope = scope.limit(limit) if limit.positive?
    matches = scope.to_a

    puts "Tournament: #{tournament.year} #{tournament.name}"
    puts "Matches without any video_link: #{matches.size}"
    puts ""

    scout = ArchiveOrgScout.new
    attached = 0
    skipped  = 0

    matches.each_with_index do |m, idx|
      label = "M#{m.match_number} #{m.home_team.fifa_code} v #{m.away_team.fifa_code}"
      hit = scout.find_best_for_match(m)
      if hit.nil?
        puts "#{label}: no relevant result"
        skipped += 1
      else
        link = m.video_links.find_or_initialize_by(url: hit["url"])
        was_new = link.new_record?
        link.assign_attributes(source: :archive_org, confidence: :unverified, language: "en", is_active: true, embed_allowed: true)
        link.save!
        puts "#{label}: → #{hit["title"].to_s.truncate(80)} (downloads: #{hit["downloads"]}) #{was_new ? "[NEW]" : "[exists]"}"
        attached += 1 if was_new
      end
      sleep 1 unless idx == matches.size - 1  # be nice to archive.org
    end

    puts ""
    puts "Attached: #{attached} new archive.org link(s). Skipped: #{skipped}."
  end

  desc "Probe oEmbed for every YouTube VideoLink and update embed_allowed. FIFA's channel is forced to false (their domain block is invisible to YouTube APIs)."
  task probe_embed_allowed: :environment do
    links = VideoLink.kept.where(source: [:youtube_official, :broadcaster]).to_a
    puts "Probing #{links.size} VideoLink(s)…"
    puts ""

    changed = 0
    forced_false = 0
    probed_true = 0
    probed_false = 0

    links.each do |link|
      desired =
        if link.source == "youtube_official"
          forced_false += 1
          false
        else
          ok = VideoLinkScout.youtube_embeddable?(link.url)
          ok ? probed_true += 1 : probed_false += 1
          ok
        end

      next if link.embed_allowed == desired
      link.update!(embed_allowed: desired)
      changed += 1
      puts "  #{link.id} (#{link.source}) → embed_allowed=#{desired} | #{link.url.truncate(80)}"
    end

    puts ""
    puts "Done. Forced false (youtube_official=FIFA): #{forced_false}, probed embeddable: #{probed_true}, probed blocked: #{probed_false}, rows updated: #{changed}."
  end

  def with_rate_limit_retry(max_retries: 2, backoff_seconds: 65)
    attempts = 0
    begin
      yield
    rescue VideoLinkScout::RateLimited => e
      attempts += 1
      raise if attempts > max_retries
      puts "  ! rate-limited (#{e.message}); sleeping #{backoff_seconds}s (attempt #{attempts}/#{max_retries})…"
      sleep backoff_seconds
      retry
    end
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
