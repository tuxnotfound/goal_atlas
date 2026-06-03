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
    # Skip goals that previously failed scouting — they'd burn quota across
    # all 6 channels and still come up empty. Admin can clear
    # video_scout_failed_at on a goal to force a retry.
    scope = Goal.joins(:match).where(matches: { tournament_id: tournament.id })
                .left_outer_joins(:video_links).where(video_links: { id: nil })
                .where(video_scout_failed_at: nil)
                .order("matches.match_number, goals.minute")
    scope = scope.limit(limit) if limit
    goals = scope.to_a

    puts "Tournament: #{tournament.year} #{tournament.name}"
    puts "Goals to scout: #{goals.size}#{limit ? " (limited)" : ""}"
    puts "Estimated YouTube quota: #{goals.size * 100}-#{goals.size * 600} units"
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
          g.update_column(:video_scout_failed_at, Time.current)
          puts "#{label}: no relevant result (marked failed; will be skipped next run)"
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

  desc "Bulk-apply heuristic timestamp suggestions to every goal video_link without starts_at_seconds, for one tournament. Usage: rake video_links:bulk_apply_timestamps[<year>]"
  task :bulk_apply_timestamps, [:year] => :environment do |_t, args|
    abort "Usage: rake video_links:bulk_apply_timestamps[<year>]" unless args[:year]

    tournament = Tournament.find_by!(year: args[:year].to_i)
    puts "Tournament: #{tournament.year} #{tournament.name}"
    matches = tournament.matches.kept.includes(goals: :video_links).to_a
    puts "Matches to process: #{matches.size}"
    puts ""

    applied = 0
    skipped = 0
    matches_touched = 0

    matches.each do |match|
      suggester = GoalTimestampSuggester.new(match)
      suggester.warm_durations!
      suggestions = suggester.suggestions_by_link
      if suggestions.empty?
        skipped += 1
        next
      end

      matches_touched += 1
      VideoLink.where(id: suggestions.keys).each do |link|
        # suggestions_by_link already filtered to links with starts_at_seconds.nil?,
        # but re-check to stay idempotent across concurrent edits.
        next unless link.starts_at_seconds.nil?
        link.update_column(:starts_at_seconds, suggestions[link.id])
        applied += 1
      end
      print "  M#{match.match_number} #{match.home_team.fifa_code} v #{match.away_team.fifa_code}: +#{suggestions.size} timestamp(s) saved\n"
    end

    puts ""
    puts "Applied: #{applied} timestamp(s) across #{matches_touched} match(es). Matches skipped (no candidates): #{skipped}."
  end

  desc "Scout British Pathé YouTube channel for pre-1970 World Cup videos and attach to identifiable matches. No args."
  task scout_pathe: :environment do
    # Fetch up to pages_to_fetch × 50 = 250 Pathé videos matching 'world cup'.
    # 100 quota units per page; 5 pages = 500 units.
    pages_to_fetch = 5
    api_key = ENV.fetch("YOUTUBE_API_KEY") {
      File.read(Rails.root.join(".env"))[/YOUTUBE_API_KEY=(.+)/, 1]
    }
    pathe_channel = VideoLinkScout::CHANNELS.fetch(:british_pathe)

    all_videos = []
    page_token = nil
    pages_to_fetch.times do |i|
      uri = URI("https://www.googleapis.com/youtube/v3/search")
      params = {
        key: api_key, part: "snippet", channelId: pathe_channel,
        q: "world cup", maxResults: 50, type: "video", order: "relevance"
      }
      params[:pageToken] = page_token if page_token
      uri.query = URI.encode_www_form(params)
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      items = data["items"] || []
      all_videos += items
      puts "Pathé page #{i + 1}: +#{items.size} (total: #{all_videos.size})"
      page_token = data["nextPageToken"]
      break unless page_token
    end

    puts ""
    puts "Inspecting #{all_videos.size} videos for FIFA World Cup match identifiability…"
    puts ""

    # Country name → Team mapping for the title parser. Includes common
    # historical names Pathé would have used (West Germany, USSR, Czechoslovakia).
    wc_years = Tournament.distinct.pluck(:year).sort
    teams_by_alias = build_team_alias_map

    attached = 0
    matched_no_attach = 0
    unmatched = 0
    log = []

    all_videos.each do |item|
      title    = item.dig("snippet", "title").to_s.gsub(/&#39;|&quot;/, "'")
      video_id = item.dig("id", "videoId")
      next unless video_id

      year = extract_wc_year(title, wc_years)
      teams = extract_teams(title, teams_by_alias)

      label = title[0, 75]
      if year.nil? || teams.size != 2
        unmatched += 1
        next
      end

      match = find_match(year, teams)
      if match.nil?
        matched_no_attach += 1
        log << "  ! #{year} #{teams.map(&:fifa_code).join(' v ')}: no match in DB | #{label}"
        next
      end

      url = "https://www.youtube.com/watch?v=#{video_id}"
      link = match.video_links.find_or_initialize_by(url: url)
      was_new = link.new_record?
      embeddable = VideoLinkScout.youtube_embeddable?(url)
      link.assign_attributes(source: :broadcaster, confidence: :unverified,
                              language: "en", is_active: true,
                              embed_allowed: embeddable)
      link.save!
      attached += 1 if was_new
      log << "  ✓ M#{match.match_number} #{teams.map(&:fifa_code).join(' v ')} #{year}: #{was_new ? 'NEW' : 'exists'} embed=#{embeddable} | #{label}"
    end

    puts log.join("\n")
    puts ""
    puts "Attached: #{attached} new | matched but no DB record: #{matched_no_attach} | unmatched: #{unmatched}"
  end

  # ----- helpers for scout_pathe -----

  # Returns hash of downcased alias → Team. Includes Pathé-era variants.
  def build_team_alias_map
    map = {}
    historical_aliases = {
      "FRG" => ["West Germany", "Germany"],
      "GDR" => ["East Germany"],
      "URS" => ["USSR", "Soviet Union", "Russia"],
      "TCH" => ["Czechoslovakia"],
      "FRY" => ["Yugoslavia"],
      "SCG" => ["Serbia and Montenegro"]
    }
    Team.kept.each do |t|
      add_alias = ->(name) { map[name.to_s.downcase] = t if name.present? && name.length > 2 }
      add_alias.call(t.name)
      add_alias.call(t.fifa_code)
      (historical_aliases[t.fifa_code] || []).each(&add_alias)
    end
    map
  end

  # Finds a 4-digit WC tournament year mentioned anywhere in the title.
  def extract_wc_year(title, wc_years)
    title.scan(/\b(19[3-9]\d|20[0-2]\d)\b/).flatten.map(&:to_i).find { |y| wc_years.include?(y) }
  end

  # Finds 2+ team aliases mentioned in the title. Returns Array of Team
  # (in order they appear), de-duplicated, capped at 2 (home/away order
  # doesn't matter for matching — we try both).
  def extract_teams(title, alias_map)
    downcased = title.downcase
    seen = {}
    alias_map.each do |name, team|
      idx = downcased.index(name)
      next unless idx
      # boundary check — alias must be surrounded by non-letter (avoid "iran" inside "irani")
      before = idx == 0 || downcased[idx - 1] !~ /[a-z]/
      after_idx = idx + name.length
      after = after_idx >= downcased.length || downcased[after_idx] !~ /[a-z]/
      next unless before && after
      seen[team.id] ||= [idx, team]
    end
    seen.values.sort_by { |idx, _| idx }.map(&:last).first(2)
  end

  # Tries both team orderings.
  def find_match(year, teams)
    return nil if teams.size != 2
    a, b = teams
    Match.joins(:tournament).where(tournaments: { year: year })
         .where("(home_team_id = ? AND away_team_id = ?) OR (home_team_id = ? AND away_team_id = ?)",
                a.id, b.id, b.id, a.id).first
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
