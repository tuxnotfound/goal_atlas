require "net/http"
require "json"

# Looks up player portraits on Wikidata + Wikimedia Commons.
#
# Returns only freely-licensed images (CC0 / CC-BY / CC-BY-SA / Public domain)
# with full attribution metadata so each result can be displayed responsibly.
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

  # Returns an Array<ImageCandidate>, filtered to freely-licensed portraits.
  def search(player_name:, max: 8)
    qid = find_player_qid(player_name)
    return [] if qid.nil?

    entity = fetch_entity(qid)
    return [] if entity.nil?

    candidates = []

    if (canonical = canonical_image_file(entity))
      add_candidate(candidates, canonical)
    end

    if (category = commons_category(entity)) && candidates.size < max
      # Cast a wider net (50 files) then keep only those whose filename starts
      # with the player's name — Commons categories include lots of tangentially
      # related media (graffiti, birthplaces, family) we don't want.
      category_files(category, 50).each do |file_name|
        next if candidates.any? { |c| c.file_name == file_name }
        next unless portrait_named?(file_name, player_name)
        add_candidate(candidates, file_name)
        break if candidates.size >= max
      end
    end

    candidates.select(&:freely_licensed?)
  end

  PHOTO_EXTENSIONS = %w[jpg jpeg png webp].freeze

  # Tokens whose presence in a filename strongly suggests it's not a portrait.
  NOISE_TOKENS = %w[
    signature firma sig graffiti maillot jersey shirt boot boots
    stadium statue monument estatua mural casa house childhood barrio infancia
    family familia trophy trophies medal medals award ribbon footprint print
    pronunciation pronounce name fans crowd autograph cartoon caricature
    drawing painting silhouette logo sticker stamp coin currency
  ].freeze

  def portrait_named?(file_name, player_name)
    ext = file_name[/\.([a-z0-9]+)\z/i, 1]&.downcase
    return false unless PHOTO_EXTENSIONS.include?(ext)

    base = normalize(file_name.sub(/\.[a-z0-9]+\z/i, ""))
    tokens = normalize(player_name).split.reject { |t| t.length < 3 }
    return false if tokens.empty?

    family = tokens.last
    name_present = base.start_with?(family) || base[0, 40].include?(family)
    return false unless name_present

    base_words = base.split
    return false if (base_words & NOISE_TOKENS).any?

    true
  end

  def normalize(str)
    str.to_s.unicode_normalize(:nfkd)
       .gsub(/[̀-ͯ]/, "")
       .downcase
       .gsub(/[^a-z0-9 ]/, " ")
       .squeeze(" ")
       .strip
  end

  private

  attr_reader :logger

  def add_candidate(list, file_name)
    info = file_info(file_name)
    list << build_candidate(file_name, info) if info
  end

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

  def commons_category(entity)
    claim_values(entity, "P373").first
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

  def category_files(category, limit)
    return [] if limit <= 0
    response = api_get(COMMONS_API,
      action: "query", list: "categorymembers",
      cmtitle: "Category:#{category}", cmtype: "file",
      cmlimit: limit, format: "json"
    )
    members = response&.dig("query", "categorymembers") || []
    members.map { |m| m["title"].to_s.sub(/^File:/, "") }
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
