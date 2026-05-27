require "net/http"
require "json"

# Scouts archive.org's free advanced-search API for match-level video
# recordings. Used for tournaments where YouTube has no licensed coverage
# (pre-2000 World Cups in particular).
#
# Archive.org has no quota or auth. Their search API:
#   https://archive.org/advancedsearch.php?q=...&output=json
#
# Usage:
#   ArchiveOrgScout.new.find_best_for_match(match)
#   # => { identifier:, title:, downloads:, url: } or nil
class ArchiveOrgScout
  SEARCH_ENDPOINT = "https://archive.org/advancedsearch.php"

  # Returns the most-downloaded archive.org item whose title plausibly matches
  # the given Match, or nil. Searches title-only with mediatype=movies to
  # avoid audio recordings and text scans.
  def find_best_for_match(match, rows: 8)
    docs = search(match_query(match), rows: rows)
    docs.find { |d| relevant_to_match?(d, match) }
  end

  def search(query, rows: 5)
    # archive.org needs fl[]=a&fl[]=b (with brackets); URI.encode_www_form
    # produces fl=a&fl=b which silently makes the API only return the last
    # field. Build the query string manually.
    params = [
      ["q", query],
      ["fl[]", "identifier"],
      ["fl[]", "title"],
      ["fl[]", "year"],
      ["fl[]", "downloads"],
      ["rows", rows.to_s],
      ["sort", "downloads desc"],
      ["output", "json"]
    ]
    uri = URI(SEARCH_ENDPOINT)
    uri.query = params.map { |k, v| "#{URI.encode_www_form_component(k)}=#{URI.encode_www_form_component(v)}" }.join("&")

    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)
    data = JSON.parse(response.body)
    (data.dig("response", "docs") || []).map do |d|
      d.merge("url" => "https://archive.org/details/#{d["identifier"]}")
    end
  rescue StandardError
    []
  end

  private

  def match_query(match)
    home = match.home_team.name.to_s.downcase
    away = match.away_team.name.to_s.downcase
    year = match.tournament&.year
    %{mediatype:movies AND title:("#{home}" AND "#{away}" AND "#{year}")}
  end

  # Title must mention BOTH teams (by name or FIFA code) — same approach as
  # VideoLinkScout#relevant_to_match? to keep behaviour consistent.
  def relevant_to_match?(doc, match)
    title = doc["title"].to_s.downcase
    return false if title.empty?
    home_keys = [match.home_team.name, match.home_team.fifa_code].compact.map(&:downcase)
    away_keys = [match.away_team.name, match.away_team.fifa_code].compact.map(&:downcase)
    home_keys.any? { |k| title.include?(k) } && away_keys.any? { |k| title.include?(k) }
  end
end
