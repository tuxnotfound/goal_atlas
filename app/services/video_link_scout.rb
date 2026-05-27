require "net/http"
require "json"

# Suggests video links for a given Goal or Match by querying the YouTube
# Data API v3, restricted to legal channels (FIFA's official channel + a
# configurable broadcaster allowlist).
#
# Setup:
#   1. Get a YouTube Data API key:
#      https://console.cloud.google.com/apis/credentials
#      (Enable "YouTube Data API v3" on the project first.)
#   2. Export it:        export YOUTUBE_API_KEY=...
#
# Usage:
#   scout = VideoLinkScout.new
#   scout.suggest_for_goal(goal)   # -> [{ title:, url:, channel:, published_at: }, ...]
#   scout.suggest_for_match(match) # -> [...]
#   scout.search("custom query")   # -> [...]
class VideoLinkScout
  API_BASE = "https://www.googleapis.com/youtube/v3/search"

  # Known channel IDs for legal/authoritative sources.
  # Keep this in sync with the Source records in db/seeds/sources.rb —
  # those are the human-readable registry; this hash is the lookup the
  # YouTube Data API needs (it filters by channelId, not channel handle).
  CHANNELS = {
    fifa:         "UCpcTrCXblq78GZrTUTLWeBw", # @FIFA (verified 2026-05-20)
    sky_sport_nz: "UC8f1U3h2TAcKOktgonnL0Yw"  # @SkySportNZ (verified 2026-05-27)
    # When adding a new tournament source:
    #   1. Add a Source record in db/seeds/sources.rb (with channel ID in notes)
    #   2. Mirror the channel ID here so the scout can filter searches to it
  }.freeze

  # VideoLink.source enum value for each channel.
  CHANNEL_SOURCES = {
    fifa:         :youtube_official,
    sky_sport_nz: :broadcaster
  }.freeze

  # Default priority order for find_best_for_goal: try FIFA first, then
  # broadcasters. Override via the `channels:` kwarg.
  DEFAULT_CHANNEL_PRIORITY = %i[fifa sky_sport_nz].freeze

  class ApiKeyMissing < StandardError; end
  class ApiError < StandardError; end
  class RateLimited < ApiError; end
  class DailyQuotaExhausted < ApiError; end

  def initialize(api_key: ENV["YOUTUBE_API_KEY"])
    @api_key = api_key
  end

  def suggest_for_goal(goal, max_results: 5, channel: :fifa)
    query = goal_query(goal)
    search(query, max_results: max_results, channel: channel)
  end

  # Picks a single best YouTube result for a goal across the given channels,
  # in priority order. Each result must pass a title-relevance check before
  # it's returned (otherwise we'd auto-attach unrelated compilation videos).
  # Returns { title:, url:, channel:, published_at:, query:, source: } or nil.
  # `source:` is the VideoLink enum value (:youtube_official or :broadcaster).
  # Each channel attempted costs 100 YouTube API quota units.
  def find_best_for_goal(goal, channels: DEFAULT_CHANNEL_PRIORITY, max_results: 5)
    channels.each do |channel|
      results = suggest_for_goal(goal, max_results: max_results, channel: channel)
      match = results.find { |r| relevant_to_goal?(r, goal) }
      next unless match
      return match.merge(source: CHANNEL_SOURCES.fetch(channel))
    end
    nil
  end

  # Same idea as find_best_for_goal but for match-level highlight reels.
  def find_best_for_match(match, channels: DEFAULT_CHANNEL_PRIORITY, max_results: 5)
    channels.each do |channel|
      results = suggest_for_match(match, max_results: max_results, channel: channel)
      hit = results.find { |r| relevant_to_match?(r, match) }
      next unless hit
      return hit.merge(source: CHANNEL_SOURCES.fetch(channel))
    end
    nil
  end

  def suggest_for_match(match, max_results: 5, channel: :fifa)
    query = match_query(match)
    search(query, max_results: max_results, channel: channel)
  end

  # channel: a symbol from CHANNELS, or nil for unrestricted search.
  def search(query, max_results: 5, channel: nil)
    raise ApiKeyMissing, "Set YOUTUBE_API_KEY env var (see VideoLinkScout docs)" if @api_key.blank?

    params = {
      key: @api_key,
      part: "snippet",
      q: query,
      type: "video",
      maxResults: max_results
    }
    params[:channelId] = CHANNELS.fetch(channel) if channel

    uri = URI(API_BASE)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    # 429 = per-minute rate limit (sleep ~60s and retry); 403 with quotaExceeded
    # in body = daily quota gone (sleep won't help, abort).
    raise RateLimited, "#{response.code}: per-minute rate limit hit" if response.code == "429"
    raise DailyQuotaExhausted, "403: daily YouTube API quota exhausted" if response.code == "403" && response.body.to_s.include?("quotaExceeded")
    raise ApiError, "#{response.code} #{response.message}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("items", []).map do |item|
      {
        title:        item.dig("snippet", "title"),
        channel:      item.dig("snippet", "channelTitle"),
        url:          "https://www.youtube.com/watch?v=#{item.dig('id', 'videoId')}",
        published_at: item.dig("snippet", "publishedAt"),
        query:        query
      }
    end
  end

  private

  def goal_query(goal)
    bits = [
      goal.player.name,
      "vs", goal.opponent_team.name,
      goal.match.tournament.year,
      stage_query_term(goal.match.stage),
      goal_modifier(goal)
    ]
    bits.compact.reject(&:blank?).join(" ")
  end

  def match_query(match)
    bits = [
      match.home_team.name,
      "v", match.away_team.name,
      match.tournament.year,
      stage_query_term(match.stage),
      "highlights"
    ]
    bits.compact.reject(&:blank?).join(" ")
  end

  def stage_query_term(stage)
    case stage.to_s
    when "final"               then "final"
    when "third_place_playoff" then "third place"
    when "semi_final"          then "semi-final"
    when "quarter_final"       then "quarter-final"
    when "round_of_16"         then "round of 16"
    when "round_of_32"         then "round of 32"
    else stage.to_s.humanize.downcase
    end
  end

  def goal_modifier(goal)
    case goal.goal_type
    when "penalty"   then "penalty"
    when "free_kick" then "free kick"
    when "own_goal"  then "own goal"
    end
  end

  # A YouTube result is "relevant" if its title mentions at least one of:
  # the scorer's name, the opponent, or the scoring team. Prevents
  # auto-attaching unrelated compilation videos that YouTube returns when
  # a channel has no specific footage for the goal.
  def relevant_to_goal?(result, goal)
    title = result[:title].to_s.downcase
    return false if title.empty?

    keywords = [
      goal.player.name,
      goal.player.name.split(/\s+/).last,
      goal.scoring_team.name,
      goal.scoring_team.fifa_code,
      goal.opponent_team.name,
      goal.opponent_team.fifa_code
    ].compact.reject(&:blank?).map(&:downcase).uniq

    keywords.any? { |kw| title.include?(kw) }
  end

  # A match-highlight result must mention BOTH teams (or both fifa codes),
  # to avoid auto-attaching reels for a different fixture that happens to
  # mention one of the teams.
  def relevant_to_match?(result, match)
    title = result[:title].to_s.downcase
    return false if title.empty?

    home_keys = [match.home_team.name, match.home_team.fifa_code].compact.map(&:downcase)
    away_keys = [match.away_team.name, match.away_team.fifa_code].compact.map(&:downcase)

    home_keys.any? { |k| title.include?(k) } && away_keys.any? { |k| title.include?(k) }
  end
end
