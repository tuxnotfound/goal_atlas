require "net/http"
require "json"
require "cgi"

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
    fifa:           "UCpcTrCXblq78GZrTUTLWeBw", # @FIFA            (verified 2026-05-20)
    sky_sport_nz:   "UC8f1U3h2TAcKOktgonnL0Yw", # @SkySportNZ      (verified 2026-05-27)
    tyc_sports:     "UC72ZaBKI-Bo5fjmWEYonhJw", # @TycSports       (verified 2026-05-27)
    tf1:            "UC26vXhYofHiZDM2ar1zUuwQ", # @TF1             (verified 2026-05-27)
    bbc_sport:      "UCW6-BQWFA70Dyyc7ZpZ9Xlg", # @bbcsport        (verified 2026-05-27)
    rtp_noticias:   "UCIM-wfyv9hg2oEiA81mQc2A", # @RTPNoticias     (verified 2026-05-27)
    british_pathe:  "UCGp4u0WHLsK8OAxnvwiTyhA"  # @BritishPathe    (verified 2026-05-30)
    # When adding a new tournament source:
    #   1. Add a Source record in db/seeds/sources.rb (with channel ID in notes)
    #   2. Mirror the channel ID here so the scout can filter searches to it
  }.freeze

  # VideoLink.source enum value for each channel.
  CHANNEL_SOURCES = {
    fifa:           :youtube_official,
    sky_sport_nz:   :broadcaster,
    tyc_sports:     :broadcaster,
    tf1:            :broadcaster,
    bbc_sport:      :broadcaster,
    rtp_noticias:   :broadcaster,
    british_pathe:  :broadcaster
  }.freeze

  # Default priority order for find_best_for_goal: try FIFA first, then
  # broadcasters. Each additional channel adds ~100 quota units per goal
  # ONLY when prior channels return nothing relevant — FIFA covers most
  # 2022+ World Cup content, so the broadcaster fallbacks rarely fire.
  DEFAULT_CHANNEL_PRIORITY = %i[fifa sky_sport_nz tyc_sports tf1 bbc_sport rtp_noticias].freeze

  # YouTube's oEmbed endpoint returns 200 + JSON when a video allows
  # third-party embedding and 401 when the uploader has blocked it.
  # Free, no quota, no auth.
  OEMBED_ENDPOINT = "https://www.youtube.com/oembed"

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
  # Returns { title:, url:, channel:, published_at:, query:, source:, embed_allowed: }
  # or nil. `source:` is the VideoLink enum value (:youtube_official or :broadcaster).
  # Each channel attempted costs 100 YouTube API quota units; non-FIFA channels
  # add one cheap oEmbed probe to decide embed_allowed.
  def find_best_for_goal(goal, channels: DEFAULT_CHANNEL_PRIORITY, max_results: 5)
    channels.each do |channel|
      results = suggest_for_goal(goal, max_results: max_results, channel: channel)
      match = results.find { |r| relevant_to_goal?(r, goal) }
      next unless match
      return decorate_with_source_and_embed(match, channel)
    end
    nil
  end

  # Same idea as find_best_for_goal but for match-level highlight reels.
  def find_best_for_match(match, channels: DEFAULT_CHANNEL_PRIORITY, max_results: 5)
    channels.each do |channel|
      results = suggest_for_match(match, max_results: max_results, channel: channel)
      hit = results.find { |r| relevant_to_match?(r, match) }
      next unless hit
      return decorate_with_source_and_embed(hit, channel)
    end
    nil
  end

  # Probes YouTube's oEmbed endpoint for `url` and returns true iff the
  # video allows third-party embedding (HTTP 200). FIFA's channel returns
  # 401 here, so this is how autofetch decides VideoLink#embed_allowed
  # automatically.
  def self.youtube_embeddable?(url, timeout: 5)
    return false if url.blank?
    uri = URI(OEMBED_ENDPOINT)
    uri.query = URI.encode_www_form(url: url, format: "json")
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true,
                               open_timeout: timeout, read_timeout: timeout) do |http|
      http.get(uri.request_uri)
    end
    response.is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
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

  # Adds source: (VideoLink enum) and embed_allowed: to a raw search result.
  # FIFA's channel is hardcoded to embed_allowed=false because YouTube's
  # oEmbed/videos.list both lie about FIFA's domain-whitelist block.
  # Other channels are probed via the cheap oEmbed endpoint.
  def decorate_with_source_and_embed(result, channel)
    source = CHANNEL_SOURCES.fetch(channel)
    embed_allowed = source != :youtube_official && self.class.youtube_embeddable?(result[:url])
    result.merge(source: source, embed_allowed: embed_allowed)
  end

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
