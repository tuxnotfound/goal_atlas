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
  # Add more here as needed (ESPN FC, Sky Sports, beIN, FOX Soccer, etc.).
  CHANNELS = {
    fifa: "UCpcTrCXblq78GZrTUTLWeBw" # @FIFA — verify on first use
  }.freeze

  class ApiKeyMissing < StandardError; end
  class ApiError < StandardError; end

  def initialize(api_key: ENV["YOUTUBE_API_KEY"])
    @api_key = api_key
  end

  def suggest_for_goal(goal, max_results: 5, channel: :fifa)
    query = goal_query(goal)
    search(query, max_results: max_results, channel: channel)
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
end
