require "net/http"
require "json"

# Looks up the canonical player portrait on Wikidata (P18) and resolves its
# license metadata via Wikimedia Commons.
#
# Returns at most ONE image per player — the curated Wikipedia infobox portrait.
# Returning the wider Commons category content is too noisy (signatures, cars,
# facilities, fan photos); admins can hand-add additional URLs if they need
# more than one image per player.
class WikimediaPortraitScout
  USER_AGENT = "GoalAtlas/0.1 (https://goalatlas.local; pcioga@gmail.com)".freeze
  WIKIDATA_API = "https://www.wikidata.org/w/api.php".freeze
  COMMONS_API  = "https://commons.wikimedia.org/w/api.php".freeze

  HUMAN_QID      = "Q5".freeze
  FOOTBALLER_QID = "Q937857".freeze

  FREE_LICENSE_REGEX = /\A(CC0|CC[- ]BY|public[- ]domain|PD)/i

  ImageCandidate = Struct.new(
    :url, :source_url, :thumbnail_url, :license, :license_url,
    :author, :description, :file_name,
    keyword_init: true
  ) do
    def freely_licensed?
      license.present? && license.match?(FREE_LICENSE_REGEX)
    end
  end

  def initialize(timeout: 10, logger: nil)
    @timeout = timeout
    @logger  = logger
  end

  # Returns an Array<ImageCandidate> of length 0 or 1.
  def search(player_name:)
    qid = find_player_qid(player_name)
    return [] if qid.nil?

    entity = fetch_entity(qid)
    return [] if entity.nil?

    file_name = canonical_image_file(entity)
    return [] if file_name.nil?

    info = file_info(file_name)
    return [] if info.nil?

    candidate = build_candidate(file_name, info)
    candidate.freely_licensed? ? [candidate] : []
  end

  private

  attr_reader :logger

  def find_player_qid(name)
    response = api_get(WIKIDATA_API,
      action: "wbsearchentities", search: name, language: "en",
      type: "item", limit: 10, format: "json"
    )
    candidates = (response || {}).fetch("search", [])
    candidates.each do |c|
      entity = fetch_entity(c["id"])
      next if entity.nil?
      return c["id"] if human?(entity) && footballer?(entity)
    end
    nil
  end

  def fetch_entity(qid)
    response = api_get(WIKIDATA_API,
      action: "wbgetentities", ids: qid, props: "claims|sitelinks", format: "json"
    )
    response&.dig("entities", qid)
  end

  def claim_values(entity, prop)
    Array(entity.dig("claims", prop)).map { |c| c.dig("mainsnak", "datavalue", "value") }
  end

  def human?(entity)
    claim_values(entity, "P31").any? { |v| v.is_a?(Hash) && v["id"] == HUMAN_QID }
  end

  def footballer?(entity)
    claim_values(entity, "P106").any? { |v| v.is_a?(Hash) && v["id"] == FOOTBALLER_QID }
  end

  def canonical_image_file(entity)
    claim_values(entity, "P18").first
  end

  def file_info(file_name)
    response = api_get(COMMONS_API,
      action: "query", titles: "File:#{file_name}",
      prop: "imageinfo", iiprop: "url|extmetadata",
      iiurlwidth: 600, format: "json"
    )
    page = response&.dig("query", "pages")&.values&.first
    info = page&.dig("imageinfo", 0)
    return nil if info.nil?

    ext = info["extmetadata"] || {}
    {
      url: info["url"],
      thumbnail_url: info["thumburl"] || info["url"],
      source_url: page["title"] ? "https://commons.wikimedia.org/wiki/#{page['title'].tr(' ', '_')}" : nil,
      license: ext.dig("LicenseShortName", "value"),
      license_url: ext.dig("LicenseUrl", "value"),
      author: strip_html(ext.dig("Artist", "value")),
      description: strip_html(ext.dig("ImageDescription", "value"))
    }
  end

  def build_candidate(file_name, info)
    ImageCandidate.new(
      url: info[:url],
      source_url: info[:source_url],
      thumbnail_url: info[:thumbnail_url],
      license: info[:license],
      license_url: info[:license_url],
      author: info[:author],
      description: info[:description],
      file_name: file_name
    )
  end

  def strip_html(html)
    return nil if html.blank?
    html.gsub(/<[^>]+>/, "").gsub(/\s+/, " ").strip
  end

  def api_get(url, **params)
    uri = URI(url)
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.read_timeout = @timeout
    http.open_timeout = @timeout

    req = Net::HTTP::Get.new(uri.request_uri)
    req["User-Agent"] = USER_AGENT

    response = http.request(req)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError => e
    logger&.warn("[WikimediaPortraitScout] #{e.class}: #{e.message} on #{uri}")
    nil
  end
end
