require "uri"
require "cgi"

# Editorial scoring rubric for player portraits. Shared by:
#   - PlayerImageImporter (during fresh Commons scout)
#   - lib/tasks/player_images.rake#tag_portraits (over persisted rows)
#
# Score is a heuristic sum: higher = better fit for "default portrait of this
# player in national-team context." See category_score/aspect_score for the
# metadata-based signals added alongside the original filename/description rules.
class PortraitScorer
  # Word-boundary form `\b\d+\b` fails on `_2018.jpg` because `_` is a word char,
  # so use digit-boundary lookarounds instead.
  WC_YEAR_REGEX = /(?<!\d)(19[3-9]\d|20[0-3]\d)(?!\d)/

  NATIONAL_COMPETITION_REGEX = /\b(euro|copa\s+am[eé]rica|nations\s+league|gold\s+cup|asian\s+cup|africa\s+cup|afcon|euros)\b/

  CLUB_PENALTY_TERMS = [
    "psg", "paris saint-germain", "manchester united", "real madrid",
    "fc barcelona", "barcelona vs", "inter miami", "tottenham", "spurs",
    "juventus", "chelsea", "manchester city", "arsenal", "liverpool",
    "al-nassr", "al nassr", "sporting cp", "atletico madrid", "atlético madrid",
    "valencia", "valladolid", "borussia", "bayern", "ajax", "psv",
    "madame tussauds", "wax", "graffiti", "mural", "statue"
  ].freeze

  def initialize(player)
    @nationality_terms = nationality_terms(player)
    @tournament_years  = Tournament.kept.pluck(:year).to_set
  end

  # Score a scout ImageCandidate (used during fresh scout via the importer).
  def score_candidate(candidate)
    score_attrs(
      file_name:   candidate.file_name,
      description: candidate.description,
      categories:  candidate.categories || [],
      width:       candidate.width,
      height:      candidate.height
    )
  end

  # Score a persisted PlayerImage (used by the tag_portraits rake task).
  def score_image(image)
    # Wikimedia URLs are percent-encoded ("%28cropped%29"); decode so the
    # filename-based rules see the same shape they do during fresh scout.
    file_name = CGI.unescape(File.basename(URI.parse(image.url).path))
    score_attrs(
      file_name:   file_name,
      description: image.description,
      categories:  image.commons_categories || [],
      width:       image.image_width,
      height:      image.image_height
    )
  end

  private

  def score_attrs(file_name:, description:, categories:, width:, height:)
    text  = "#{file_name} #{description}".downcase.tr("_", " ")
    score = 0

    score += 12 if text.match?(/\b(fifa\s+)?world\s+cup\b/) || text.match?(/\bwc\s*\d{4}\b/)
    score += 8  if text.match?(NATIONAL_COMPETITION_REGEX)
    score += 6  if text.match?(/\bqualif/) && @nationality_terms.any? { |t| text.include?(t) }
    score += 5  if text.match?(/\bnational\s+team\b/) || text.match?(/\bselection\b/)
    score += 5  if @nationality_terms.any? { |t| text.include?(t) }

    text.scan(WC_YEAR_REGEX).flatten.uniq.each do |year|
      score += 4 if @tournament_years.include?(year.to_i)
    end

    score -= 6 if CLUB_PENALTY_TERMS.any? { |t| text.include?(t) }

    score += category_score(categories)
    score += aspect_score(width, height)
    score += 3 if (description || "").match?(/\b(portrait|headshot|close-?up)\b/i)

    # Wikimedia's "(cropped)" filename convention almost always means a
    # tight head/shoulders crop — the strongest portrait-shape signal we have
    # from the filename alone.
    score += 6 if file_name.to_s.match?(/\(cropped\)/i)

    score
  end

  # Commons categories are curated by hand and carry strong signal. The
  # "Portraits of X" hierarchy is the most reliable indicator that a file is
  # a clean head/shoulders shot rather than an action photo or team scene.
  def category_score(categories)
    return 0 if categories.blank?
    text  = categories.join(" | ").downcase
    score = 0
    score += 12 if text.include?("portraits of") || text.match?(/\bportrait/)
    score += 6  if text.match?(/\b(fifa\s+)?world\s+cup\b/)
    score += 4  if text.match?(/\bnational\s+(football\s+)?team\b/) || text.match?(/\bselection\b/) || text.match?(/\bsquad\b/)
    score -= 4  if text.match?(/\bgroup\s+photos\b/) || text.match?(/\bteam\s+photographs\b/)
    score
  end

  # Aspect ratio is a cheap proxy for framing. Portraits are taller than wide;
  # action shots are usually 3:2 landscape. Squarish covers tightly-cropped
  # headshots either way.
  def aspect_score(width, height)
    w, h = width.to_i, height.to_i
    return 0 if w.zero? || h.zero?
    ratio = h.to_f / w
    case ratio
    when 1.3..2.5  then 5
    when 0.85..1.3 then 3
    when 0.0..0.6  then -3
    else 0
    end
  end

  def nationality_terms(player)
    team = player.nationality_team
    return [] if team.nil?
    [team.name, team.fifa_code, team.country_code].compact.map(&:downcase).uniq
  end
end
