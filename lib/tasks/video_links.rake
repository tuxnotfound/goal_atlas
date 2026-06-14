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

  # rescout_short_highlights makes up to 4 fallback searches per match,
  # which can burst close to the per-minute ceiling. 10s sleep gives more
  # headroom and was empirically needed during the WC2018 run.
  RESCOUT_SLEEP_SECONDS = 10

  desc "Auto-attach FIFA/broadcaster YouTube highlight reels to MATCHES in a tournament that lack any video link. Usage: rake video_links:autofetch_matches[<year>,<limit>]"
  task :autofetch_matches, [:year, :limit] => :environment do |_t, args|
    abort "Usage: rake video_links:autofetch_matches[<year>,<limit?>]" unless args[:year]
    limit = args[:limit].to_i
    limit = nil if limit.zero?

    tournament = Tournament.find_by!(year: args[:year].to_i)
    # Skip matches that already failed all channels in a previous run — they'd
    # burn ~600 quota units (6 channels × 100u) and still come up empty.
    # Admin can clear video_scout_failed_at to force a retry.
    scope = tournament.matches.left_outer_joins(:video_links)
                       .where(video_links: { id: nil })
                       .where(video_scout_failed_at: nil)
                       .order(:match_number)
    scope = scope.limit(limit) if limit
    matches = scope.to_a

    puts "Tournament: #{tournament.year} #{tournament.name}"
    puts "Matches to scout: #{matches.size}#{limit ? " (limited)" : ""}"
    puts "Estimated YouTube quota: #{matches.size * 100}-#{matches.size * 600} units"
    puts "Throttling: #{AUTOFETCH_SLEEP_SECONDS}s between API calls (~#{matches.size * AUTOFETCH_SLEEP_SECONDS}s minimum)"
    puts ""

    scout = VideoLinkScout.new
    attached = 0
    skipped  = 0

    begin
      matches.each_with_index do |m, idx|
        label = "M#{m.match_number} #{m.home_team.fifa_code} v #{m.away_team.fifa_code}"
        result = with_rate_limit_retry { scout.find_best_for_match(m) }
        if result.nil?
          m.update_column(:video_scout_failed_at, Time.current)
          puts "#{label}: no relevant result (marked failed; will be skipped next run)"
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
    rescue VideoLinkScout::DailyQuotaExhausted => e
      puts ""
      puts "Stopping early: #{e.message}."
      puts "Re-run the same task tomorrow (after the YouTube quota resets) to continue."
    end

    puts ""
    puts "Attached: #{attached} new match-level link(s). Skipped: #{skipped}."
  end

  desc "Search YouTube broadly (no channel filter) with 'fifa YEAR highlights HOME AWAY' for every match in a tournament that lacks any YouTube link. ONE search per match (quota-efficient) — top result attached if title contains both team names. Apt for older tournaments (pre-2010) where FIFA's official channel doesn't archive everything. Usage: rake 'video_links:search_for_unlinked_matches[<year>,<mode=dry|apply>,<limit>]'"
  task :search_for_unlinked_matches, [:year, :mode, :limit] => :environment do |_t, args|
    abort "Usage: rake 'video_links:search_for_unlinked_matches[<year>,<mode=dry|apply>,<limit?>]'" unless args[:year]
    mode = (args[:mode] || "dry").downcase
    abort "mode must be 'dry' or 'apply'" unless %w[dry apply].include?(mode)
    limit = args[:limit].to_i.zero? ? nil : args[:limit].to_i

    tournament = Tournament.find_by!(year: args[:year].to_i)

    # Matches without ANY kept YouTube link.
    already_yt_ids = tournament.matches.kept.joins(:video_links)
                               .where(video_links: { discarded_at: nil, is_active: true })
                               .where("video_links.url LIKE ? OR video_links.url LIKE ?", *YOUTUBE_URL_LIKE)
                               .distinct.pluck(:id)

    scope = tournament.matches.kept.where.not(id: already_yt_ids)
                      .where(video_scout_failed_at: nil)
                      .includes(:home_team, :away_team)
                      .order(:match_number)
    scope = scope.limit(limit) if limit
    matches = scope.to_a

    puts "Tournament: #{tournament.year} #{tournament.name}  |  Mode: #{mode.upcase}"
    puts "Matches without YouTube link: #{matches.size}"
    puts "Estimated quota: ~#{matches.size * 100} units (1 search per match; daily cap 10000)"
    puts ""

    scout       = VideoLinkScout.new
    attached    = 0
    weak_result = 0
    no_result   = 0

    matches.each_with_index do |match, idx|
      home = match.home_team.name
      away = match.away_team.name
      year = tournament.year
      query = "fifa #{year} highlights #{home} #{away}"
      label = "M#{match.match_number} #{home} v #{away}"

      begin
        results = with_rate_limit_retry { scout.search(query, max_results: 5, channel: nil) }
      rescue VideoLinkScout::DailyQuotaExhausted => e
        puts ""
        puts "Stopping early: #{e.message}."
        puts "Re-run the same task tomorrow (after the YouTube quota resets) to continue."
        break
      end

      if results.empty?
        puts "#{label}: NO RESULTS"
        no_result += 1
        sleep AUTOFETCH_SLEEP_SECONDS unless idx == matches.size - 1
        next
      end

      # Score each result on title relevance and pick the best.
      best = results.max_by do |r|
        title = r[:title].to_s.downcase
        s = 0
        s += 3 if title.include?(home.downcase)
        s += 3 if title.include?(away.downcase)
        s += 2 if title.include?(year.to_s)
        s += 1 if title.match?(/highlight|fifa|world cup|goals/)
        s
      end

      title_lower = best[:title].to_s.downcase
      both_teams_in_title = title_lower.include?(home.downcase) && title_lower.include?(away.downcase)

      if !both_teams_in_title
        puts "#{label}: WEAK (top: #{best[:title].to_s.slice(0, 70)} | #{best[:url]})"
        weak_result += 1
        sleep AUTOFETCH_SLEEP_SECONDS unless idx == matches.size - 1
        next
      end

      puts "#{label}: -> #{best[:url]}"
      puts "  title:   #{best[:title]}"
      puts "  channel: #{best[:channel]}"

      if mode == "apply"
        link = match.video_links.find_or_initialize_by(url: best[:url])
        if link.new_record?
          link.assign_attributes(
            source:        "other",
            confidence:    :unverified,
            language:      "en",
            is_active:     true,
            embed_allowed: false
          )
          link.save!
          attached += 1
        end
      end

      sleep AUTOFETCH_SLEEP_SECONDS unless idx == matches.size - 1
    end

    puts ""
    puts "Attached: #{attached} | Weak (no team match in title): #{weak_result} | No results: #{no_result}"
    puts "(Dry run — nothing written. Re-run with mode=apply to attach.)" if mode == "dry"
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

  desc "Use Gemini multimodal model to identify goal timestamps for a tournament's unvalidated YouTube links. Usage: rake video_links:gemini_apply_timestamps[<year>,<mode=dry|apply>,<limit>]"
  task :gemini_apply_timestamps, [:year, :mode, :limit] => :environment do |_t, args|
    abort "Usage: rake video_links:gemini_apply_timestamps[<year>,<mode=dry|apply>,<limit?>]" unless args[:year]
    mode  = (args[:mode] || "dry").downcase
    abort "mode must be 'dry' or 'apply'" unless %w[dry apply].include?(mode)
    limit = args[:limit].to_i
    limit = nil if limit.zero?

    tournament = Tournament.find_by!(year: args[:year].to_i)

    # Goals to scout: in this tournament, not discarded, and without ANY validated link.
    validated_goal_ids = Goal.kept.joins(:match, :video_links)
                             .where(matches: { tournament_id: tournament.id })
                             .where.not(video_links: { timestamp_validated_at: nil, discarded_at: nil })
                             .pluck(:id).uniq

    goals_scope = Goal.kept.joins(:match)
                      .where(matches: { tournament_id: tournament.id })
                      .where.not(id: validated_goal_ids)
                      .includes(:player, :scoring_team, match: [:home_team, :away_team, :tournament], video_links: [])
                      .order("matches.match_number, goals.minute")
    goals_scope = goals_scope.limit(limit) if limit

    goals = goals_scope.to_a
    puts "Tournament: #{tournament.year} #{tournament.name}"
    puts "Mode: #{mode.upcase}  Limit: #{limit || "none"}"
    puts "Goals to scout: #{goals.size} (skipping #{validated_goal_ids.size} with validated links)"
    puts ""

    scout = GeminiTimestampScout.new
    examined = 0
    written  = 0
    skipped  = 0
    failed   = 0
    mismatches = []

    goals.each do |goal|
      links = goal.video_links.select { |l| l.kept? && l.is_active && l.url.to_s.match?(%r{youtu\.?be}) }
      if links.empty?
        skipped += 1
        next
      end

      links.each do |link|
        # Skip goals that already have a timestamp — re-runs after a rescout
        # would otherwise re-pay Gemini for goals whose URLs didn't change.
        # Rescout NULLs starts_at_seconds on links it replaces, so only
        # those (and never-Gemini'd goals) will be processed here.
        next if link.starts_at_seconds.present?
        examined += 1
        label = "M#{goal.match.match_number} #{goal.minute}' #{goal.player.name}"
        result = scout.suggest(goal, link)
        if result.nil?
          puts "  #{label}: FAILED (no response)"
          failed += 1
          next
        end

        before = link.starts_at_seconds
        new_value = result[:timestamp_seconds]
        # Gemini returns timestamp_seconds=-1 (or 0 with confidence=low) when
        # the goal isn't in the clip — typically a mis-attached link. Don't
        # write those; collect them for a follow-up reattribution pass.
        skip_write = result[:confidence] == "low" || new_value.negative?
        delta = before ? new_value - before : nil
        line = "  #{label}: Gemini=#{new_value}s (conf=#{result[:confidence]})"
        line << " | was=#{before}s (Δ=#{delta&.positive? ? "+#{delta}" : delta}s)" if before
        line << " [MISMATCH — recorded]" if skip_write
        line << " | #{result[:notes].to_s.slice(0, 60)}" if result[:notes].present?
        puts line

        if skip_write
          mismatches << {
            video_link_id: link.id,
            match_number:  goal.match.match_number,
            match_label:   "#{goal.match.home_team.fifa_code} v #{goal.match.away_team.fifa_code}",
            goal_minute:   goal.minute,
            goal_player:   goal.player.name,
            scoring_team:  goal.scoring_team.fifa_code,
            current_url:   link.url,
            gemini_notes:  result[:notes],
          }
        elsif mode == "apply"
          link.update_column(:starts_at_seconds, new_value)
          written += 1
        end
      rescue GeminiTimestampScout::Error => e
        puts "  #{label}: ERROR #{e.message}"
        failed += 1
      end
      sleep 1 # gentle throttle
    end

    puts ""
    puts "Examined: #{examined} link(s) | Written: #{written} | Failed: #{failed} | Mismatches: #{mismatches.size} | Goals skipped (no eligible link): #{skipped}"
    puts "(Dry run — nothing written. Re-run with mode=apply to commit.)" if mode == "dry"

    if mismatches.any?
      require "json"
      path = Rails.root.join("tmp/mismatched_videos_#{tournament.year}_#{Time.current.strftime("%Y%m%d_%H%M%S")}.json")
      File.write(path, JSON.pretty_generate(mismatches))
      puts "Mismatches written to #{path}"
    end
  end

  desc "Read a mismatches JSON file and ask Gemini what match each mis-attached video actually shows. Writes a proposal report — never modifies the DB. Usage: rake video_links:resolve_mismatches[<path>]"
  task :resolve_mismatches, [:path] => :environment do |_t, args|
    require "json"
    path = args[:path] || Dir.glob(Rails.root.join("tmp/mismatched_videos_*.json")).max_by { |f| File.mtime(f) }
    abort "Usage: rake video_links:resolve_mismatches[<path>] (no file found and none given)" unless path && File.exist?(path)

    mismatches = JSON.parse(File.read(path))
    puts "Source file: #{path}"
    puts "Mismatches to resolve: #{mismatches.size}"
    puts ""

    scout = GeminiTimestampScout.new
    alias_map = build_team_alias_map

    proposals = []
    mismatches.each do |m|
      label = "M#{m["match_number"]} #{m["match_label"]} | #{m["goal_minute"]}' #{m["goal_player"]}"
      puts "Resolving: #{label}"
      puts "  URL: #{m["current_url"]}"
      result = scout.identify_match(m["current_url"])
      if result.nil?
        puts "  → Gemini returned no response"
        proposals << m.merge("resolution" => "no_response")
        next
      end

      puts "  → Gemini says: #{result[:year]} #{result[:competition]} | #{result[:home_team]} vs #{result[:away_team]} (conf=#{result[:confidence]})"
      puts "  → Notes: #{result[:notes].slice(0, 120)}" if result[:notes].present?

      team_a = lookup_team_by_name(result[:home_team], alias_map)
      team_b = lookup_team_by_name(result[:away_team], alias_map)
      year   = result[:year]

      proposal = m.merge(
        "gemini_year"      => year,
        "gemini_home"      => result[:home_team],
        "gemini_away"      => result[:away_team],
        "gemini_conf"      => result[:confidence],
        "gemini_extra"     => result[:notes]
      )

      if team_a.nil? || team_b.nil? || year.nil?
        puts "  → COULDN'T RESOLVE teams/year in DB"
        proposal["resolution"] = "unresolved"
      else
        proposed_match = Match.joins(:tournament).where(tournaments: { year: year })
                              .where("(home_team_id = ? AND away_team_id = ?) OR (home_team_id = ? AND away_team_id = ?)",
                                     team_a.id, team_b.id, team_b.id, team_a.id)
                              .first
        current_link = VideoLink.find_by(id: m["video_link_id"])
        current_match = nil
        if current_link
          current_match = current_link.linkable.is_a?(Match) ? current_link.linkable : current_link.linkable&.match
        end

        if proposed_match.nil?
          puts "  → MATCH NOT IN DB (#{year} #{team_a.fifa_code} v #{team_b.fifa_code})"
          proposal["resolution"] = "match_not_in_db"
        elsif current_match && proposed_match.id == current_match.id
          puts "  → SAME MATCH as currently attached — Gemini's timestamp mismatch was likely a model error, not a wrong URL"
          proposal["resolution"] = "gemini_was_wrong"
          proposal["matched_match_id"] = proposed_match.id
        else
          puts "  → SUGGEST RE-ATTACH to M#{proposed_match.match_number} #{proposed_match.home_team.fifa_code} v #{proposed_match.away_team.fifa_code} (#{proposed_match.date})"
          proposal["resolution"] = "reattach_proposed"
          proposal["matched_match_id"] = proposed_match.id
          proposal["matched_match_label"] = "M#{proposed_match.match_number} #{proposed_match.home_team.fifa_code} v #{proposed_match.away_team.fifa_code}"
          proposal["matched_match_slug"] = proposed_match.slug
        end
      end
      proposals << proposal
      puts ""
      sleep 1
    end

    out_path = Rails.root.join("tmp/mismatch_resolutions_#{Time.current.strftime("%Y%m%d_%H%M%S")}.json")
    File.write(out_path, JSON.pretty_generate(proposals))
    puts "Resolution proposals written to #{out_path}"
    puts ""
    by_resolution = proposals.group_by { |p| p["resolution"] }
    by_resolution.each { |k, v| puts "  #{k}: #{v.size}" }
  end

  def lookup_team_by_name(name, alias_map)
    return nil if name.blank?
    alias_map[name.downcase] || alias_map[name.downcase.strip]
  end

  # YouTube URLs only — Gemini can only process those, and a parallel
  # non-YouTube link wouldn't help the auto-timestamp flow.
  YOUTUBE_URL_LIKE = ["%youtube.com%", "%youtu.be%"].freeze

  desc "Find a YouTube short-highlight for every match in a tournament that doesn't have one yet. Skips matches that already have a kept-active YouTube link or any admin-validated content. Uses VideoLinkScout's blacklist-aware fallback chain. Propagates the found URL to all of the match's goals. Idempotent. Usage: rake video_links:fill_youtube_highlights[<year>,<mode=dry|apply>]"
  task :fill_youtube_highlights, [:year, :mode] => :environment do |_t, args|
    abort "Usage: rake video_links:fill_youtube_highlights[<year>,<mode>]" unless args[:year]
    mode = (args[:mode] || "dry").downcase
    abort "mode must be 'dry' or 'apply'" unless %w[dry apply].include?(mode)

    tournament = Tournament.find_by!(year: args[:year].to_i)
    matches = tournament.matches.kept.order(:match_number).to_a
    puts "Tournament: #{tournament.year} #{tournament.name}  |  Mode: #{mode.upcase}"
    puts "Total matches: #{matches.size}"
    puts ""

    scout = VideoLinkScout.new
    filled = already_yt = validated_skipped = not_found = quota_dead = 0

    matches.each_with_index do |match, idx|
      label = "M#{match.match_number} #{match.home_team.fifa_code} v #{match.away_team.fifa_code}"

      # Skip if a kept-active YouTube link already exists at match level
      if match.video_links.kept.active
              .where("url LIKE ? OR url LIKE ?", "%youtube.com%", "%youtu.be%").exists?
        already_yt += 1; next
      end

      # Skip if admin has validated any link (match or goal level) for this match
      has_validated = match.video_links.kept.where.not(timestamp_validated_at: nil).exists? ||
                      Goal.kept.where(match_id: match.id).joins(:video_links)
                          .where(video_links: { discarded_at: nil })
                          .where.not(video_links: { timestamp_validated_at: nil }).exists?
      if has_validated
        puts "#{label}: SKIPPED (admin-validated)"
        validated_skipped += 1; next
      end

      begin
        result = with_rate_limit_retry { scout.find_best_short_match_video_with_fallback(match) }
      rescue VideoLinkScout::DailyQuotaExhausted => e
        puts "#{label}: quota exhausted — STOPPING (#{e.message[0,80]})"
        quota_dead = idx
        break
      end

      if result.nil?
        puts "#{label}: no YouTube short clip found (with fallback + blacklist)"
        not_found += 1
        sleep RESCOUT_SLEEP_SECONDS unless idx == matches.size - 1
        next
      end

      new_url = result[:url]
      puts "#{label}: → #{new_url}"

      if mode == "apply"
        ActiveRecord::Base.transaction do
          match.video_links.create!(
            url:           new_url,
            source:        result[:source],
            confidence:    :unverified,
            language:      "en",
            is_active:     true,
            embed_allowed: result.fetch(:embed_allowed, false),
          )
          Goal.kept.where(match_id: match.id).each do |goal|
            # Don't double-propagate if the goal already has a YouTube link
            next if goal.video_links.kept.active
                        .where("url LIKE ? OR url LIKE ?", "%youtube.com%", "%youtu.be%").exists?
            goal.video_links.create!(
              url:               new_url,
              source:            result[:source],
              confidence:        :unverified,
              language:          "en",
              is_active:         true,
              embed_allowed:     result.fetch(:embed_allowed, false),
              starts_at_seconds: nil,
            )
          end
        end
      end

      filled += 1
      sleep RESCOUT_SLEEP_SECONDS unless idx == matches.size - 1
    end

    puts ""
    puts "Filled: #{filled} | Already had YouTube: #{already_yt} | Admin-validated skip: #{validated_skipped} | Not found: #{not_found} | Quota-stopped at idx #{quota_dead || "n/a"}"
    puts "(Dry run — no DB changes. Re-run with mode=apply to commit.)" if mode == "dry"
  end

  desc "For each goal in a tournament whose match has a YouTube video_link, attach that same video to the goal (if the goal lacks a YouTube link). Idempotent. Usage: rake video_links:propagate_match_videos_to_goals[<year>,<mode=dry|apply>]"
  task :propagate_match_videos_to_goals, [:year, :mode] => :environment do |_t, args|
    abort "Usage: rake video_links:propagate_match_videos_to_goals[<year>,<mode=dry|apply>]" unless args[:year]
    mode = (args[:mode] || "dry").downcase
    abort "mode must be 'dry' or 'apply'" unless %w[dry apply].include?(mode)

    tournament = Tournament.find_by!(year: args[:year].to_i)
    puts "Tournament: #{tournament.year} #{tournament.name}  |  Mode: #{mode.upcase}"
    puts ""

    matches_with_yt = tournament.matches.kept
                                .joins(:video_links)
                                .where(video_links: { discarded_at: nil, is_active: true })
                                .where("video_links.url LIKE ? OR video_links.url LIKE ?", *YOUTUBE_URL_LIKE)
                                .distinct
                                .includes(:video_links, goals: :video_links)
    puts "Matches with at least one active YouTube link: #{matches_with_yt.size}"

    propagated = 0
    skipped    = 0
    matches_touched = 0

    matches_with_yt.each do |match|
      yt_match_links = match.video_links.select do |vl|
        vl.kept? && vl.is_active && vl.url.match?(%r{youtu\.?be})
      end
      next if yt_match_links.empty?

      # Prefer youtube_official > broadcaster > others (most likely to be a full reel)
      source_link = yt_match_links.min_by do |vl|
        case vl.source
        when "youtube_official" then 0
        when "broadcaster"      then 1
        else                          2
        end
      end

      match_label = "M#{match.match_number} #{match.home_team.fifa_code} v #{match.away_team.fifa_code}"
      touched_in_match = 0

      match.goals.kept.each do |goal|
        if goal.video_links.any? { |vl| vl.kept? && vl.is_active && vl.url.match?(%r{youtu\.?be}) }
          skipped += 1
          next
        end

        if mode == "apply"
          goal.video_links.create!(
            url:               source_link.url,
            source:            source_link.source,
            confidence:        :unverified,
            language:          source_link.language || "en",
            is_active:         true,
            embed_allowed:     source_link.embed_allowed,
            starts_at_seconds: nil,
          )
        end

        propagated += 1
        touched_in_match += 1
      end

      if touched_in_match.positive?
        matches_touched += 1
        puts "  #{match_label}: +#{touched_in_match} goal-level link(s) from #{source_link.url.slice(-22, 22)} (#{source_link.source})"
      end
    end

    puts ""
    puts "Propagated: #{propagated} new goal-level link(s) across #{matches_touched} match(es). Skipped (goal already has YouTube link): #{skipped}."
    puts "(Dry run — no DB changes. Re-run with mode=apply to commit.)" if mode == "dry"
  end

  desc "Re-scout each match in a tournament for a short (<4min) YouTube highlight ('Home Away YEAR World Cup' query); replace existing YouTube links at both match- and goal-level, then propagate. Skips matches that have any admin-validated link. Usage: rake video_links:rescout_short_highlights[<year>,<mode=dry|apply>]"
  task :rescout_short_highlights, [:year, :mode] => :environment do |_t, args|
    abort "Usage: rake video_links:rescout_short_highlights[<year>,<mode>]" unless args[:year]
    mode = (args[:mode] || "dry").downcase
    abort "mode must be 'dry' or 'apply'" unless %w[dry apply].include?(mode)

    tournament = Tournament.find_by!(year: args[:year].to_i)
    matches = tournament.matches.kept.order(:match_number).to_a
    puts "Tournament: #{tournament.year} #{tournament.name}  |  Mode: #{mode.upcase}"
    puts "Matches in tournament: #{matches.size}"
    puts ""

    scout = VideoLinkScout.new
    rescouted        = 0
    skipped_validated = 0
    not_found        = 0
    unchanged        = 0

    matches.each_with_index do |match, idx|
      label = "M#{match.match_number} #{match.home_team.fifa_code} v #{match.away_team.fifa_code}"

      # Skip if any link on this match or its goals is admin-validated.
      validated = match.video_links.kept.where.not(timestamp_validated_at: nil).exists? ||
                  Goal.kept.where(match_id: match.id).joins(:video_links)
                      .where(video_links: { discarded_at: nil })
                      .where.not(video_links: { timestamp_validated_at: nil }).exists?
      if validated
        puts "#{label}: SKIPPED (has admin-validated link)"
        skipped_validated += 1
        next
      end

      begin
        result = with_rate_limit_retry { scout.find_best_short_match_video_with_fallback(match) }
      rescue VideoLinkScout::DailyQuotaExhausted => e
        puts "#{label}: quota exhausted — STOPPING (#{e.message[0,80]})"
        break
      end
      if result.nil?
        puts "#{label}: no highlight found (tried short and medium)"
        not_found += 1
        sleep RESCOUT_SLEEP_SECONDS unless idx == matches.size - 1
        next
      end

      new_url = result[:url]

      # If the SAME URL is already attached at match level, nothing to do.
      current_match_yt = match.video_links.kept.active
                              .where("url LIKE ? OR url LIKE ?", "%youtube.com%", "%youtu.be%")
                              .pluck(:url)
      if current_match_yt == [new_url]
        puts "#{label}: already on #{new_url.slice(-22, 22)} — no change"
        unchanged += 1
        sleep RESCOUT_SLEEP_SECONDS unless idx == matches.size - 1
        next
      end

      puts "#{label}: → #{new_url} (replacing #{current_match_yt.size} existing match-level YT link(s))"

      if mode == "apply"
        ActiveRecord::Base.transaction do
          # Soft-delete every kept YouTube link on this match or its goals
          match.video_links.kept
               .where("url LIKE ? OR url LIKE ?", "%youtube.com%", "%youtu.be%")
               .each { |vl| vl.update!(is_active: false, discarded_at: Time.current) }
          Goal.kept.where(match_id: match.id).each do |goal|
            goal.video_links.kept
                .where("url LIKE ? OR url LIKE ?", "%youtube.com%", "%youtu.be%")
                .each { |vl| vl.update!(is_active: false, discarded_at: Time.current) }
          end

          # Attach the new short URL at match level
          match.video_links.create!(
            url:           new_url,
            source:        result[:source],
            confidence:    :unverified,
            language:      "en",
            is_active:     true,
            embed_allowed: result.fetch(:embed_allowed, false),
          )

          # Propagate to every goal in the match
          Goal.kept.where(match_id: match.id).each do |goal|
            goal.video_links.create!(
              url:               new_url,
              source:            result[:source],
              confidence:        :unverified,
              language:          "en",
              is_active:         true,
              embed_allowed:     result.fetch(:embed_allowed, false),
              starts_at_seconds: nil,
            )
          end
        end
      end

      rescouted += 1
      sleep RESCOUT_SLEEP_SECONDS unless idx == matches.size - 1
    end

    puts ""
    puts "Rescouted: #{rescouted} | Already on the right URL: #{unchanged} | No short highlight found: #{not_found} | Validated-skipped: #{skipped_validated}"
    puts "(Dry run — no DB changes. Re-run with mode=apply to commit.)" if mode == "dry"
  end

  desc "Apply re-attachment proposals from a resolution JSON. Moves video_links to the matched Match (match-level), clears starts_at_seconds, sets confidence: unverified. Usage: rake video_links:apply_mismatch_resolutions[<path>,<mode=dry|apply>]"
  task :apply_mismatch_resolutions, [:path, :mode] => :environment do |_t, args|
    require "json"
    path = args[:path] || Dir.glob(Rails.root.join("tmp/mismatch_resolutions_*.json")).max_by { |f| File.mtime(f) }
    abort "Usage: rake video_links:apply_mismatch_resolutions[<path>,<mode>] (no resolutions file found and none given)" unless path && File.exist?(path)
    mode = (args[:mode] || "dry").downcase
    abort "mode must be 'dry' or 'apply'" unless %w[dry apply].include?(mode)

    proposals = JSON.parse(File.read(path))
    reattach = proposals.select { |p| p["resolution"] == "reattach_proposed" }
    puts "Source: #{path}"
    puts "Mode: #{mode.upcase}  |  re-attach proposals: #{reattach.size}"
    puts ""

    applied = 0
    skipped = 0

    reattach.each do |p|
      link  = VideoLink.find_by(id: p["video_link_id"])
      match = Match.find_by(id: p["matched_match_id"])
      original_label = "#{p["match_label"]} #{p["goal_minute"]}' #{p["goal_player"]}"
      target_label   = p["matched_match_label"]
      if link.nil?
        puts "  link_id=#{p["video_link_id"]}: NOT FOUND in DB — skipping"
        skipped += 1; next
      end
      if match.nil?
        puts "  link_id=#{p["video_link_id"]}: target match_id=#{p["matched_match_id"]} NOT FOUND — skipping"
        skipped += 1; next
      end
      # Safety: don't clobber admin edits made since the mismatch was recorded.
      if link.url != p["current_url"]
        puts "  ⚠ #{original_label}: URL CHANGED since mismatch (recorded=#{p["current_url"].slice(-22, 22)} current=#{link.url.slice(-22, 22)}) — skipping"
        skipped += 1; next
      end
      if link.timestamp_validated_at.present?
        puts "  ⚠ #{original_label}: timestamp_validated_at set — admin has validated this link, skipping"
        skipped += 1; next
      end

      action = "#{original_label} → #{target_label} | url=#{link.url.slice(-22, 22)}"
      if mode == "apply"
        link.update!(
          linkable_type:          "Match",
          linkable_id:            match.id,
          starts_at_seconds:      nil,
          confidence:             :unverified,
          timestamp_validated_at: nil
        )
        puts "  ✓ MOVED: #{action}"
        applied += 1
      else
        puts "  WOULD MOVE: #{action}"
      end
    end

    puts ""
    puts "Applied: #{applied}  |  Skipped: #{skipped}  |  Not re-attachable (other resolutions): #{proposals.size - reattach.size}"
    puts "(Dry run — no DB changes. Re-run with mode=apply to commit.)" if mode == "dry"
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

  # YouTube sometimes returns HTTP 429 ("per-minute rate limit") when the
  # daily quota is actually exhausted — sleeping doesn't recover. After
  # exhausting retries, treat it as a daily-quota event so the task can
  # exit gracefully with the "re-run tomorrow" message rather than crash
  # with a stack trace.
  def with_rate_limit_retry(max_retries: 2, backoff_seconds: 65)
    attempts = 0
    begin
      yield
    rescue VideoLinkScout::RateLimited => e
      attempts += 1
      if attempts > max_retries
        raise VideoLinkScout::DailyQuotaExhausted,
              "persistent 429 after #{max_retries} retries (#{e.message}) — treating as quota exhaustion"
      end
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
