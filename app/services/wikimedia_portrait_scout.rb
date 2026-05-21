require "net/http"
require "json"

# Looks up player portraits across multiple Wikimedia sources, ranked by
# authority:
#
#   1. Wikidata P18 (the canonical infobox image)
#   2. Each language Wikipedia's article lead image (en/es/pt/fr/de/it)
#   3. English Wikipedia inline images whose filename matches the player's
#      surname (skips flag icons, league logos, signatures, etc.)
#
# Each candidate's license metadata is resolved via the Commons API and only
# freely-licensed images (CC0, CC-BY, CC-BY-SA, Public Domain) are returned.
class WikimediaPortraitScout
  USER_AGENT = "GoalAtlas/0.1 (https://goalatlas.local; pcioga@gmail.com)".freeze
  WIKIDATA_API = "https://www.wikidata.org/w/api.php".freeze
  COMMONS_API  = "https://commons.wikimedia.org/w/api.php".freeze

  HUMAN_QID      = "Q5".freeze
  FOOTBALLER_QID = "Q937857".freeze

  LANGUAGES = %w[en es pt fr de it].freeze

  PHOTO_EXTENSIONS = %w[jpg jpeg png webp].freeze

  # Filename substrings that signal "not a portrait" — graffiti, signatures,
  # facilities, cars, statues, etc. Compared case-insensitively as substrings
  # so concatenated names like "FirmadeLionelMessi..." also get caught.
  NOISE_SUBSTRINGS = %w[
    signature firma graffiti maillot jersey shirt boot stadium statue monument
    mural casa house childhood barrio infancia family familia trophy medal
    ribbon footprint pronunciation autograph cartoon caricature
    drawing painting silhouette sticker stamp coin currency
    escultura museu museo museum statua estatua
    bresh fan car coche auto vehiculo predio deportivo plaque facility
  ].freeze

  TEAM_PHOTO_SIGNALS = %w[national world fifa selection selecao seleccion squad team].freeze

  FREE_LICENSE_REGEX = /\A(CC0|CC[- ]BY|public[- ]domain|PD)/i

  # Large enough to give the importer scoring layer a real pool to choose
  # from across nationality / World Cup / regional-competition queries.
  MAX_CANDIDATES = 30

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

  # Returns an ordered Array<ImageCandidate>, most authoritative first.
  # competition_terms is a list of strings (e.g. ["World Cup", "UEFA Euro",
  # "Nations League"]) that get combined with the player's name to run
  # Commons File-namespace searches. This is what surfaces national-team
  # photos that the Wikipedia/Wikidata layers don't have.
  def search(player_name:, nationality: nil, competition_terms: ["World Cup"], max: MAX_CANDIDATES)
    qid = find_player_qid(player_name)
    return [] if qid.nil?

    entity = fetch_entity(qid)
    return [] if entity.nil?

    filenames = collect_filenames(entity, player_name, nationality, competition_terms).first(max * 2)
    return [] if filenames.empty?

    filenames.filter_map { |fn|
      info = file_info(fn)
      next nil if info.nil?
      build_candidate(fn, info)
    }.select(&:freely_licensed?).first(max)
  end

  private

  attr_reader :logger

  def collect_filenames(entity, player_name, nationality, competition_terms)
    filenames = []

    # 1. Wikidata P18 (canonical)
    if (canonical = canonical_image_file(entity))
      filenames << canonical
    end

    # 2. Commons File-namespace search — nationality + competition queries
    # pull national-team-kit photos. Run early so they aren't truncated by
    # the per-player cap when biographical sources are abundant.
    sitelinks = entity["sitelinks"] || {}
    queries = []
    queries << %("#{player_name}" #{nationality}) if nationality.present?
    competition_terms.each do |term|
      queries << %("#{player_name}" "#{term}")
    end
    queries.each do |q|
      filenames += commons_search_portraits(q, player_name, nationality)
    end

    # 3. Per-language Wikipedia lead images
    LANGUAGES.each do |lang|
      sitelink = sitelinks["#{lang}wiki"]
      next if sitelink.nil?
      lead = wikipedia_lead_image(lang, sitelink["title"])
      filenames << lead if lead
    end

    # 4. English Wikipedia inline images (surname-filtered)
    if (en = sitelinks["enwiki"])
      filenames += wikipedia_inline_portraits(en["title"], player_name)
    end

    # Commons and Wikipedia APIs return the same file with spaces or underscores
    # interchangeably; normalize before deduping.
    filenames.compact.map { |fn| fn.to_s.tr(" ", "_") }.uniq
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

  def wikipedia_lead_image(lang, title)
    response = api_get(wikipedia_api(lang),
      action: "query", prop: "pageimages",
      titles: title, piprop: "name|original",
      pilicense: "any", format: "json"
    )
    page = response&.dig("query", "pages")&.values&.first
    page&.dig("pageimage")
  end

  def wikipedia_inline_portraits(title, player_name)
    response = api_get(wikipedia_api("en"),
      action: "parse", page: title, prop: "images",
      format: "json"
    )
    images = response&.dig("parse", "images") || []
    images.select { |fn| portrait_like?(fn, player_name) }
  end

  def commons_search_portraits(query, player_name, nationality = nil)
    response = api_get(COMMONS_API,
      action: "query", list: "search",
      srsearch: query, srnamespace: 6,
      srlimit: 20, format: "json"
    )
    hits = response&.dig("query", "search") || []
    hits.map { |h| h["title"].to_s.sub(/^File:/, "") }
        .select { |fn| portrait_like?(fn, player_name) || team_photo_like?(fn, nationality) }
  end

  # Looser filter for "Portugal national football team [date].jpg" type files
  # surfaced by Commons search: require nationality + a team/squad signal,
  # since the player's name may not be in the filename for group photos.
  def team_photo_like?(file_name, nationality)
    return false if nationality.blank?
    ext = file_name[/\.([a-z0-9]+)\z/i, 1]&.downcase
    return false unless PHOTO_EXTENSIONS.include?(ext)

    base = normalize(file_name.sub(/\.[a-z0-9]+\z/i, ""))
    return false unless base.include?(normalize(nationality))
    return false unless TEAM_PHOTO_SIGNALS.any? { |t| base.include?(t) }
    return false if NOISE_SUBSTRINGS.any? { |t| base.include?(t) }
    true
  end

  def portrait_like?(file_name, player_name)
    ext = file_name[/\.([a-z0-9]+)\z/i, 1]&.downcase
    return false unless PHOTO_EXTENSIONS.include?(ext)

    base = normalize(file_name.sub(/\.[a-z0-9]+\z/i, ""))
    family = normalize(player_name).split.reject { |t| t.length < 3 }.last
    return false if family.nil?
    return false unless base.include?(family)
    return false if NOISE_SUBSTRINGS.any? { |t| base.include?(t) }

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

  def wikipedia_api(lang)
    "https://#{lang}.wikipedia.org/w/api.php"
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
