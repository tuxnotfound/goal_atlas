require "net/http"
require "json"
require "uri"

# Minimal GET client for api-sports.io's API-Football. Reads the key from
# API_FOOTBALL_KEY env var. Returns parsed JSON or raises.
#
# Docs: https://www.api-football.com/documentation-v3
# Free tier: 100 req/day, seasons 2022-2024 only.
# Pro tier:  current season (2026 for WC).
class ApiFootballClient
  BASE_URL = "https://v3.football.api-sports.io".freeze

  class Error < StandardError; end

  def initialize(api_key: ENV["API_FOOTBALL_KEY"])
    raise Error, "API_FOOTBALL_KEY not configured" if api_key.blank?
    @api_key = api_key
  end

  # GET /fixtures?league=1&season=2026[&date=YYYY-MM-DD]
  # Returns the parsed response. Each element has fixture, league, teams, goals, score keys.
  def fixtures(league:, season:, date: nil, from: nil, to: nil)
    params = { league: league, season: season }
    params[:date] = date if date
    params[:from] = from if from
    params[:to]   = to   if to
    get("/fixtures", params)
  end

  # GET /fixtures?id=N — single fixture; richer payload than the list view.
  def fixture(id:)
    get("/fixtures", { id: id })
  end

  # GET /teams?league=1&season=2026 — for mapping api-football team IDs to ours.
  def teams(league:, season:)
    get("/teams", { league: league, season: season })
  end

  # GET /fixtures/events?fixture=<id> — goal/card/sub timeline for one fixture.
  def fixture_events(fixture_id:)
    get("/fixtures/events", { fixture: fixture_id })
  end

  # GET /players?id=<id>&season=<season> — full player details (firstname,
  # lastname, birth date, photo). Used to upgrade short names like
  # "J. Quinones" into the canonical "Julián Andrés Quiñones Quiñones".
  def player_details(id:, season:)
    get("/players", { id: id, season: season })
  end

  private

  def get(path, params)
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params)

    req = Net::HTTP::Get.new(uri)
    req["x-apisports-key"] = @api_key
    req["Accept"] = "application/json"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30) do |http|
      http.request(req)
    end

    raise Error, "HTTP #{res.code}: #{res.body[0, 200]}" unless res.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(res.body)
    if payload["errors"].is_a?(Hash) && payload["errors"].any?
      raise Error, "API errors: #{payload["errors"].inspect}"
    end

    payload
  end
end
