require "net/http"
require "json"

# Suggests a starts_at_seconds for each goal that links to a match-highlight
# video. We can't determine the exact moment without a transcript, but we can
# give the admin a reasonable starting point to scrub from.
#
# Strategy: assume the highlight reel shows N goals chronologically, padded
# by ~20s intro + ~20s outro. Slot goal i at the midpoint of its share of the
# usable middle.
#
# Usage:
#   suggester = GoalTimestampSuggester.new(match)
#   suggester.suggest_for(goal)               # => Integer seconds, or nil
#   suggester.suggestions_by_video_link_id    # => { vl_id => { goal_id => seconds } }
class GoalTimestampSuggester
  INTRO_PADDING_SECONDS = 20
  OUTRO_PADDING_SECONDS = 20
  YOUTUBE_VIDEOS_ENDPOINT = "https://www.googleapis.com/youtube/v3/videos"

  def initialize(match, api_key: ENV["YOUTUBE_API_KEY"])
    @match = match
    @api_key = api_key
  end

  # For every active YouTube link on every goal in the match, returns a
  # suggested starts_at_seconds (only when the link currently has no value
  # AND the link's video duration is known or fetchable).
  #
  # { video_link_id => suggested_seconds }
  def suggestions_by_link
    out = {}
    @match.goals.kept.ordered_within_match.each do |goal|
      goal.video_links.kept.active.each do |link|
        next unless link.starts_at_seconds.nil?
        seconds = suggest(goal, link)
        out[link.id] = seconds if seconds
      end
    end
    out
  end

  # Suggests a timestamp for a single (goal, link) pair, fetching duration
  # via the YouTube API if not already cached on the VideoLink.
  def suggest(goal, link)
    return nil unless youtube_video_id(link.url)
    duration = link.video_duration_seconds || fetch_and_cache_duration(link)
    return nil if duration.blank? || duration < (INTRO_PADDING_SECONDS + OUTRO_PADDING_SECONDS + 30)
    slot_for(goal, duration)
  end

  # Batch-fetches and caches video durations for all YouTube VideoLinks in
  # the match that don't have one yet. 1 quota unit per batch of up to 50.
  def warm_durations!
    links_missing_duration = match_youtube_links.reject { |l| l.video_duration_seconds.present? }
    return if links_missing_duration.empty?
    fetch_and_cache_durations(links_missing_duration)
  end

  private

  # Place goal i (0-indexed within its match's chronological order) at the
  # midpoint of its share of the usable middle of the video.
  def slot_for(goal, duration)
    goals = @match.goals.kept.ordered_within_match.to_a
    idx = goals.index(goal)
    return nil unless idx
    n = goals.size
    return nil if n.zero?
    usable = duration - INTRO_PADDING_SECONDS - OUTRO_PADDING_SECONDS
    return nil if usable <= 0
    (INTRO_PADDING_SECONDS + ((idx + 0.5) * usable / n)).to_i
  end

  def youtube_video_id(url)
    match = url.to_s.match(%r{(?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|v/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{11})})
    match && match[1]
  end

  def fetch_and_cache_duration(link)
    fetch_and_cache_durations([link])
    link.reload.video_duration_seconds
  end

  def fetch_and_cache_durations(links)
    return if links.empty?
    ids = links.map { |l| youtube_video_id(l.url) }.compact.uniq
    return if ids.empty? || @api_key.blank?

    uri = URI(YOUTUBE_VIDEOS_ENDPOINT)
    uri.query = URI.encode_www_form(key: @api_key, part: "contentDetails", id: ids.join(","))
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    duration_by_id = {}
    (data["items"] || []).each do |item|
      duration_by_id[item["id"]] = parse_iso8601_duration(item.dig("contentDetails", "duration"))
    end

    links.each do |link|
      id = youtube_video_id(link.url)
      next unless id && duration_by_id[id]
      link.update_column(:video_duration_seconds, duration_by_id[id])
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
