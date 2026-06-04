require "net/http"
require "json"

# Asks Gemini 2.5 Flash to identify the exact goal moment in a YouTube
# match-highlight video. Gemini natively processes the video (audio + frames)
# via the file_data API with a YouTube URL — no download needed.
#
# Returns a hash { timestamp_seconds:, confidence:, notes: } or nil on failure.
#
# Usage:
#   scout = GeminiTimestampScout.new
#   scout.suggest(goal, video_link)
class GeminiTimestampScout
  ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent".freeze
  READ_TIMEOUT_SECONDS = 120
  MAX_RETRIES = 1

  RETRYABLE_HTTP_CODES = %w[429 500 502 503 504].freeze

  class Error < StandardError; end
  class RetryableError < StandardError; end

  def initialize(api_key: ENV["GEMINI_API_KEY"])
    @api_key = api_key
  end

  # Returns { timestamp_seconds:, confidence:, notes: } or nil.
  def suggest(goal, link)
    return nil if @api_key.blank? || link.url.blank?

    body = request_body(goal, link)
    attempts = 0
    begin
      response = post_json(body)
      unless response.is_a?(Net::HTTPSuccess)
        if RETRYABLE_HTTP_CODES.include?(response.code)
          raise RetryableError, "HTTP #{response.code}: #{response.body.to_s.slice(0, 200)}"
        end
        raise Error, "HTTP #{response.code}: #{response.body.to_s.slice(0, 200)}"
      end

      parsed_response = JSON.parse(response.body)
      candidate = parsed_response.dig("candidates", 0)
      finish_reason = candidate&.dig("finishReason")
      text = candidate&.dig("content", "parts", 0, "text")

      if text.blank?
        raise Error, "empty response (finishReason=#{finish_reason || "nil"})"
      end

      parsed = JSON.parse(text)
      {
        timestamp_seconds: parsed["timestamp_seconds"].to_i,
        confidence:        parsed["confidence"].to_s,
        notes:             parsed["notes"].to_s,
      }
    rescue RetryableError, Net::ReadTimeout, Net::OpenTimeout, IOError => e
      attempts += 1
      if attempts <= MAX_RETRIES
        sleep 2 if e.is_a?(RetryableError)
        retry
      end
      raise Error, "#{e.class}: #{e.message} (after #{attempts} attempts)"
    rescue JSON::ParserError => e
      raise Error, "#{e.class}: #{e.message}"
    end
  end

  # Asks Gemini to identify which match the video actually shows. Useful
  # for the mismatch re-attribution flow when a link's content doesn't
  # match the goal it's attached to.
  #
  # Returns { year:, competition:, home_team:, away_team:, confidence:, notes: }
  # or nil. Team names are whatever Gemini wrote — caller resolves them.
  def identify_match(url)
    return nil if @api_key.blank? || url.blank?

    body = {
      contents: [{
        parts: [
          { file_data: { file_uri: url } },
          { text: identify_match_prompt }
        ]
      }],
      generationConfig: {
        response_mime_type: "application/json",
        response_schema: {
          type: "object",
          properties: {
            year:        { type: "integer" },
            competition: { type: "string" },
            home_team:   { type: "string" },
            away_team:   { type: "string" },
            confidence:  { type: "string", enum: %w[high medium low] },
            notes:       { type: "string" }
          },
          required: %w[confidence]
        }
      }
    }
    response = post_json(body)
    return nil unless response.is_a?(Net::HTTPSuccess)
    text = JSON.parse(response.body).dig("candidates", 0, "content", "parts", 0, "text")
    return nil if text.blank?
    parsed = JSON.parse(text)
    {
      year:        parsed["year"]&.to_i,
      competition: parsed["competition"].to_s,
      home_team:   parsed["home_team"].to_s,
      away_team:   parsed["away_team"].to_s,
      confidence:  parsed["confidence"].to_s,
      notes:       parsed["notes"].to_s,
    }
  rescue JSON::ParserError, Net::ReadTimeout, Net::OpenTimeout, IOError => e
    raise Error, "#{e.class}: #{e.message}"
  end

  private

  def identify_match_prompt
    <<~PROMPT
      This YouTube video shows football match highlights or a goal clip. Identify exactly which match it depicts.

      Return JSON with: year (the year the match was played), competition (e.g., "FIFA World Cup", "UEFA Champions League"), home_team and away_team (use common English names — e.g., "Portugal", "Saudi Arabia", "West Germany" if pre-1990), confidence ("high" if you can clearly identify the match, "medium" if only one team or the year is uncertain, "low" if you cannot tell), and notes (any details that informed your identification, e.g., commentators, on-screen graphics, stadium, kit colors).

      If the video does not clearly depict a single match (e.g., it's a compilation across years), set confidence to "low" and explain in notes.
    PROMPT
  end


  def request_body(goal, link)
    match = goal.match
    {
      contents: [{
        parts: [
          { file_data: { file_uri: link.url } },
          { text: prompt_for(goal, match) }
        ]
      }],
      generationConfig: {
        response_mime_type: "application/json",
        response_schema: {
          type: "object",
          properties: {
            timestamp_seconds: { type: "integer" },
            confidence:        { type: "string", enum: %w[high medium low] },
            notes:             { type: "string" }
          },
          required: %w[timestamp_seconds confidence]
        }
      }
    }
  end

  def prompt_for(goal, match)
    home = match.home_team.name
    away = match.away_team.name
    year = match.tournament&.year
    <<~PROMPT
      This YouTube video shows football highlights from the FIFA World Cup #{year} match #{home} vs #{away}.
      Identify the timestamp (seconds from start of video) marking the START OF THE SCORING SEQUENCE for the goal by #{goal.player.name} in the #{goal.minute}' minute.

      The "scoring sequence" is the immediate build-up to the goal — the final pass, run, dribble, set-piece kick, or shot setup that leads directly to the ball crossing the line. Typically 2–15 seconds before the ball crosses the line. The viewer should see the full play, not just the moment of contact.

      Do NOT return the moment the ball crosses the goal line — that comes at the END of the sequence. Do NOT include unrelated earlier possession either; start when the action that becomes the goal begins.

      If the video opens mid-play with the scoring sequence already underway, use timestamp 0.
      If multiple goals appear in the video, select the one scored by #{goal.player.name}.
      Set confidence to "high" if the scoring sequence is clearly identifiable, "medium" if you can locate it with some ambiguity, "low" if uncertain or the goal does not appear in the video.
      Return JSON only.
    PROMPT
  end

  def post_json(body)
    uri = URI("#{ENDPOINT}?key=#{@api_key}")
    req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    req.body = body.to_json
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: READ_TIMEOUT_SECONDS) { |h| h.request(req) }
  end
end
