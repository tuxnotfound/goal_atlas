require "net/http"
require "json"

# Suggests a starts_at_seconds for each goal that links to a match-highlight
# video on YouTube.
#
# Strategy, in order of confidence:
#   1. Parse chapter markers from the video description (e.g. "0:32 Messi
#      opens the scoring") and match each chapter to a goal by the scorer's
#      last name. When this works it gives near-exact timestamps.
#   2. Fall back to a minute-weighted slot: project the goal's match-clock
#      minute (0..90, or 0..120 if extra time) onto the usable middle of
#      the video. Better than equal-spacing for late goals.
#
# Usage:
#   suggester = GoalTimestampSuggester.new(match)
#   suggester.warm_durations!                 # one API call per ~50 links
#   suggester.suggestions_by_link             # => { vl_id => seconds }
class GoalTimestampSuggester
  INTRO_PADDING_SECONDS = 20
  OUTRO_PADDING_SECONDS = 20
  MIN_USABLE_DURATION   = INTRO_PADDING_SECONDS + OUTRO_PADDING_SECONDS + 30
  YOUTUBE_VIDEOS_ENDPOINT = "https://www.googleapis.com/youtube/v3/videos"

  def initialize(match, api_key: ENV["YOUTUBE_API_KEY"])
    @match = match
    @api_key = api_key
    @descriptions_by_link_id = {}
  end

  # For every active YouTube link on every goal in the match, returns a
  # suggested starts_at_seconds (only when the link currently has no value).
  # Goals with any admin-validated timestamp are skipped entirely — we don't
  # want to suggest over manual work even on a goal's other links.
  #
  # { video_link_id => suggested_seconds }
  def suggestions_by_link
    out = {}
    @match.goals.kept.ordered_within_match.each do |goal|
      next if goal_has_validated_timestamp?(goal)
      goal.video_links.kept.active.each do |link|
        next unless link.starts_at_seconds.nil?
        seconds = suggest(goal, link)
        out[link.id] = seconds if seconds
      end
    end
    out
  end

  # Suggests a timestamp for a single (goal, link) pair. Tries chapters first,
  # then falls back to minute-weighted slotting.
  def suggest(goal, link)
    return nil unless youtube_video_id(link.url)
    duration = link.video_duration_seconds || fetch_and_cache_video_data(link)
    return nil if duration.blank? || duration < MIN_USABLE_DURATION

    from_chapters = suggest_from_chapters(goal, link, duration)
    return from_chapters if from_chapters

    minute_weighted_slot(goal, duration)
  end

  # Batch-fetches and caches video durations + descriptions for all YouTube
  # VideoLinks in the match. 1 quota unit per batch of up to 50.
  def warm_durations!
    return if match_youtube_links.empty?
    fetch_and_cache_video_data_for(match_youtube_links)
  end

  private

  def goal_has_validated_timestamp?(goal)
    goal.video_links.kept.active.any? { |l| l.timestamp_validated_at.present? }
  end

  # Tries to find a chapter in the link's description whose title contains
  # the goal scorer's name. Returns the chapter's start seconds, or nil.
  def suggest_from_chapters(goal, link, duration)
    description = @descriptions_by_link_id[link.id]
    return nil if description.blank?

    chapters = parse_chapters(description)
    return nil if chapters.empty?

    chapter = chapter_for_goal(chapters, goal)
    return nil unless chapter
    return nil if chapter[:seconds] >= duration
    chapter[:seconds]
  end

  # Place the goal at a position in the usable middle proportional to its
  # match-clock minute (regulation + stoppage) over the total match length.
  # A 5' goal lands near the start; an 89' goal lands near the end.
  def minute_weighted_slot(goal, duration)
    usable = duration - INTRO_PADDING_SECONDS - OUTRO_PADDING_SECONDS
    return nil if usable <= 0

    position = goal_clock_position(goal)
    (INTRO_PADDING_SECONDS + position * usable).to_i
      .clamp(INTRO_PADDING_SECONDS, duration - OUTRO_PADDING_SECONDS)
  end

  # Normalized [0.0..1.0] position of the goal within match-clock time.
  def goal_clock_position(goal)
    total = match_total_minutes
    effective_minute = goal.minute.to_f + (goal.stoppage_time || 0).to_f
    (effective_minute / total).clamp(0.0, 1.0)
  end

  def match_total_minutes
    case @match.result_type
    when "after_extra_time", "after_penalties" then 120
    else 90
    end
  end

  # Parses chapter-like lines from a YouTube description. Returns an array of
  # { seconds:, title: } sorted ascending by seconds, with duplicates dropped.
  # Handles "M:SS Title", "MM:SS - Title", "H:MM:SS Title", with optional
  # leading bracketing characters.
  def parse_chapters(description)
    chapters = []
    description.each_line do |raw|
      line = raw.strip.sub(/\A[\[\(]/, "")
      next unless line =~ /\A(?:(\d{1,2}):)?(\d{1,2}):(\d{2})\)?\]?[\s\-–—:|·]*(.*)\z/
      hours = Regexp.last_match(1).to_i
      mins  = Regexp.last_match(2).to_i
      secs  = Regexp.last_match(3).to_i
      title = Regexp.last_match(4).to_s.strip
      next if mins > 59 || secs > 59
      seconds = hours * 3600 + mins * 60 + secs
      chapters << { seconds: seconds, title: title }
    end
    chapters.uniq { |c| c[:seconds] }.sort_by { |c| c[:seconds] }
  end

  # Picks the chapter that mentions this goal's scorer. If the scorer has
  # multiple goals in this match (a brace/hat-trick), the Nth same-scorer
  # chapter is matched to the Nth same-scorer goal in chronological order.
  def chapter_for_goal(chapters, goal)
    candidates = scorer_name_candidates(goal.player)
    return nil if candidates.empty?

    matching = chapters.select { |c| chapter_mentions_any?(c[:title], candidates) }
    return nil if matching.empty?

    same_scorer_goals = @match.goals.kept.ordered_within_match
                              .select { |g| g.player_id == goal.player_id }
    idx = same_scorer_goals.index { |g| g.id == goal.id } || 0
    matching[idx] || matching.last
  end

  # Returns candidate name tokens to look for in a chapter title, in
  # decreasing order of distinctiveness. Accents are stripped.
  # E.g. "Ángel Di María" => ["di maria", "maria", "angel"].
  def scorer_name_candidates(player)
    return [] if player.nil? || player.name.blank?
    tokens = player.name.split(/\s+/).map { |t| normalize_text(t) }.reject(&:empty?)
    return [] if tokens.empty?

    candidates = []
    candidates << tokens.drop(1).join(" ") if tokens.size > 1
    candidates << tokens.last
    candidates << tokens.first
    candidates.reject { |c| c.length < 4 }.uniq
  end

  def chapter_mentions_any?(title, candidates)
    normalized = normalize_text(title)
    candidates.any? { |c| normalized.match?(/(?<![a-z])#{Regexp.escape(c)}(?![a-z])/) }
  end

  def normalize_text(str)
    str.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase
  end

  def youtube_video_id(url)
    match = url.to_s.match(%r{(?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|v/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})})
    match && match[1]
  end

  # Single-link convenience wrapper.
  def fetch_and_cache_video_data(link)
    fetch_and_cache_video_data_for([link])
    link.reload.video_duration_seconds
  end

  # Fetches both duration and description in one videos.list call. Persists
  # duration to the VideoLink; caches description in memory only.
  def fetch_and_cache_video_data_for(links)
    return if links.empty? || @api_key.blank?
    ids = links.map { |l| youtube_video_id(l.url) }.compact.uniq
    return if ids.empty?

    uri = URI(YOUTUBE_VIDEOS_ENDPOINT)
    uri.query = URI.encode_www_form(key: @api_key, part: "contentDetails,snippet", id: ids.join(","))
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    duration_by_id = {}
    description_by_id = {}
    (data["items"] || []).each do |item|
      duration_by_id[item["id"]] = parse_iso8601_duration(item.dig("contentDetails", "duration"))
      description_by_id[item["id"]] = item.dig("snippet", "description").to_s
    end

    links.each do |link|
      id = youtube_video_id(link.url)
      next unless id
      if duration_by_id[id] && link.video_duration_seconds.blank?
        link.update_column(:video_duration_seconds, duration_by_id[id])
      end
      @descriptions_by_link_id[link.id] = description_by_id[id] if description_by_id[id]
    end
  end

  # YouTube returns durations like "PT8M37S". Convert to integer seconds.
  def parse_iso8601_duration(iso)
    return nil if iso.blank?
    h = iso[/(\d+)H/, 1].to_i
    m = iso[/(\d+)M/, 1].to_i
    s = iso[/(\d+)S/, 1].to_i
    h * 3600 + m * 60 + s
  end

  def match_youtube_links
    (@match.goals.flat_map(&:video_links) + @match.video_links.to_a)
      .select(&:kept?)
      .select(&:is_active)
      .select { |l| youtube_video_id(l.url) }
      .uniq
  end
end
