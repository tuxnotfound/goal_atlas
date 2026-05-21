# Coordinates portrait scouting for a single player:
#   1. Calls WikimediaPortraitScout
#   2. Scores each candidate on editorial fit (World Cup / national team)
#   3. Persists ordered PlayerImage rows
#   4. Auto-tags images with Tournament records when descriptions match years
#
# Idempotent: re-running for a player skips already-saved URLs but still
# refreshes tournament taggings for existing rows.
class PlayerImageImporter
  # Word-boundary form `\b\d+\b` fails on `_2018.jpg` because `_` is a word char,
  # so use digit-boundary lookarounds instead.
  WC_YEAR_REGEX = /(?<!\d)(19[3-9]\d|20[0-3]\d)(?!\d)/

  # Clubs and venues that signal "this is NOT a national-team photo."
  CLUB_PENALTY_TERMS = [
    "psg", "paris saint-germain", "manchester united", "real madrid",
    "fc barcelona", "barcelona vs", "inter miami", "tottenham", "spurs",
    "juventus", "chelsea", "manchester city", "arsenal", "liverpool",
    "al-nassr", "al nassr", "sporting cp", "atletico madrid", "atlético madrid",
    "valencia", "valladolid", "borussia", "bayern", "ajax", "psv",
    "madame tussauds", "wax", "graffiti", "mural", "statue"
  ].freeze

  Result = Struct.new(:player, :candidates, :added, :tournament_tags, keyword_init: true)

  def initialize(player, scout: nil, logger: nil)
    @player = player
    @scout = scout || WikimediaPortraitScout.new(logger: logger)
    @tournament_years = Tournament.kept.pluck(:year).to_set
    @tournaments_by_year = Tournament.kept.index_by(&:year)
    @nationality_terms = nationality_terms(player)
  end

  def import!
    candidates = @scout.search(player_name: @player.name, nationality: @player.nationality_team&.name)
    return Result.new(player: @player, candidates: [], added: [], tournament_tags: 0) if candidates.empty?

    scored = candidates
               .map { |c| [editorial_score(c), c] }
               .sort_by { |s, _| -s }
               .map { |_, c| c }

    added = []
    tags  = 0
    scored.each_with_index do |c, i|
      image = @player.player_images.find_or_initialize_by(url: c.url)
      is_new = image.new_record?

      if is_new
        image.assign_attributes(
          source_url:    c.source_url,
          thumbnail_url: c.thumbnail_url,
          license:       c.license,
          license_url:   c.license_url,
          author:        c.author,
          description:   c.description,
          position:      @player.player_images.maximum(:position).to_i + 1 + i,
          is_default:    @player.player_images.default.none? && i.zero?,
          is_active:     true,
          fetched_at:    Time.current
        )
        image.save!
        added << image
      end

      tags += apply_tournament_tags(image, c)
    end

    Result.new(player: @player, candidates: scored, added: added, tournament_tags: tags)
  end

  private

  def editorial_score(candidate)
    text = "#{candidate.file_name} #{candidate.description}".downcase
    score = 0

    score += 10 if text.match?(/\bfifa\s+world\s+cup\b/) || text.match?(/\bworld\s+cup\b/)
    score += 5  if text.match?(/\bnational\s+team\b/) || text.match?(/\bselection\b/)
    score += 5  if @nationality_terms.any? { |t| text.include?(t) }

    text.scan(WC_YEAR_REGEX).flatten.uniq.each do |year|
      score += 4 if @tournament_years.include?(year.to_i)
    end

    score -= 6 if CLUB_PENALTY_TERMS.any? { |t| text.include?(t) }

    score
  end

  def apply_tournament_tags(image, candidate)
    text = "#{candidate.file_name} #{candidate.description}".downcase
    years = text.scan(WC_YEAR_REGEX).flatten.map(&:to_i).uniq

    added = 0
    years.each do |year|
      tournament = @tournaments_by_year[year]
      next if tournament.nil?
      next if image.tournaments.exists?(id: tournament.id)
      image.tournaments << tournament
      added += 1
    end
    added
  rescue ActiveRecord::RecordNotUnique
    # Race / duplicate; tagging already exists.
    0
  end

  def nationality_terms(player)
    team = player.nationality_team
    return [] if team.nil?
    [team.name, team.fifa_code, team.country_code].compact.map(&:downcase).uniq
  end
end
