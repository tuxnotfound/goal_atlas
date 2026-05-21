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

  # National-team competitions worth searching Commons for. Generic World Cup
  # terms apply to everyone; the rest are added based on the player's
  # confederation so we surface Euro/Copa América/AFCON/etc. photos.
  COMMON_COMPETITION_TERMS = ["World Cup", "World Cup qualifying"].freeze

  CONFEDERATION_COMPETITION_TERMS = {
    uefa:     ["UEFA Euro", "Euro qualifying", "Nations League"],
    conmebol: ["Copa América", "Copa America"],
    concacaf: ["Gold Cup", "Concacaf Nations League"],
    afc:      ["AFC Asian Cup", "Asian Cup qualifying"],
    caf:      ["Africa Cup of Nations", "AFCON"],
    ofc:      ["OFC Nations Cup"]
  }.freeze

  # Score boosts when a candidate's description/filename mentions a non-WC
  # national-team competition (for editorial ranking, not auto-tagging — we
  # only have WC tournaments in the DB).
  NATIONAL_COMPETITION_REGEX = /\b(euro|copa\s+am[eé]rica|nations\s+league|gold\s+cup|asian\s+cup|africa\s+cup|afcon|euros)\b/

  # Clubs and venues that signal "this is NOT a national-team photo."
  CLUB_PENALTY_TERMS = [
    "psg", "paris saint-germain", "manchester united", "real madrid",
    "fc barcelona", "barcelona vs", "inter miami", "tottenham", "spurs",
    "juventus", "chelsea", "manchester city", "arsenal", "liverpool",
    "al-nassr", "al nassr", "sporting cp", "atletico madrid", "atlético madrid",
    "valencia", "valladolid", "borussia", "bayern", "ajax", "psv",
    "madame tussauds", "wax", "graffiti", "mural", "statue"
  ].freeze

  SAVE_LIMIT = 12

  Result = Struct.new(:player, :candidates, :added, :tournament_tags, keyword_init: true)

  def initialize(player, scout: nil, logger: nil)
    @player = player
    @scout = scout || WikimediaPortraitScout.new(logger: logger)
    @tournament_years = Tournament.kept.pluck(:year).to_set
    @tournaments_by_year = Tournament.kept.index_by(&:year)
    @nationality_terms = nationality_terms(player)
    @competition_terms = competition_terms_for(player)
  end

  def import!
    candidates = @scout.search(
      player_name: @player.name,
      nationality: @player.nationality_team&.name,
      competition_terms: @competition_terms
    )
    return Result.new(player: @player, candidates: [], added: [], tournament_tags: 0) if candidates.empty?

    scored = candidates
               .map { |c| [editorial_score(c), c] }
               .sort_by { |s, _| -s }
               .map { |_, c| c }

    # Diversity cap — at most 2 candidates from the same filename stem so a
    # single press-shoot sequence (e.g. "Cristiano_Ronaldo_0866/0876/0889…")
    # doesn't crowd out context-rich photos from other events.
    stem_counts = Hash.new(0)
    scored = scored.select do |c|
      stem = filename_stem(c.file_name)
      stem_counts[stem] += 1
      stem_counts[stem] <= 2
    end.first(SAVE_LIMIT)

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
    text = normalized_text(candidate)
    score = 0

    # "World Cup" / "FIFA World Cup" full mentions plus "WC2022"-style shorthand.
    score += 12 if text.match?(/\b(fifa\s+)?world\s+cup\b/) || text.match?(/\bwc\s*\d{4}\b/)
    score += 8  if text.match?(NATIONAL_COMPETITION_REGEX)
    score += 6  if text.match?(/\bqualif/) && @nationality_terms.any? { |t| text.include?(t) }
    score += 5  if text.match?(/\bnational\s+team\b/) || text.match?(/\bselection\b/)
    score += 5  if @nationality_terms.any? { |t| text.include?(t) }

    text.scan(WC_YEAR_REGEX).flatten.uniq.each do |year|
      score += 4 if @tournament_years.include?(year.to_i)
    end

    score -= 6 if CLUB_PENALTY_TERMS.any? { |t| text.include?(t) }

    score
  end

  def competition_terms_for(player)
    team = player.nationality_team
    return COMMON_COMPETITION_TERMS if team.nil?
    confed = team.confederation&.to_sym
    extra = CONFEDERATION_COMPETITION_TERMS[confed] || []
    COMMON_COMPETITION_TERMS + extra
  end

  def apply_tournament_tags(image, candidate)
    text = normalized_text(candidate)
    years = text.scan(WC_YEAR_REGEX).flatten.map(&:to_i).uniq

    # File names like "Cristiano_Ronaldo_WC2022_-_01.jpg" pack the year next to
    # "WC"; the lookahead regex above misses those, so scan for them too.
    text.scan(/\bwc\s*(20[12]\d|19[3-9]\d)\b/).flatten.each { |y| years << y.to_i }
    years.uniq!

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

  # Replace underscores with spaces so regex word boundaries / `\s+` patterns
  # match on filenames like "Iran_and_Portugal_match_FIFA_World_Cup_2018.jpg".
  def normalized_text(candidate)
    "#{candidate.file_name} #{candidate.description}".downcase.tr("_", " ")
  end

  # Group "Cristiano_Ronaldo_0866.jpg" / "..._0876.jpg" / "..._2275_(cropped).jpg"
  # / "..._2277.jpg" under the same stem so the diversity cap can dedupe them.
  # Years like 1986/2018/2022 are preserved because they carry signal.
  # Sequence numbers (e.g., "_5" / "_9" at the end of match-photo names) and
  # parenthesized qualifiers (e.g., "(cropped)") are also stripped.
  def filename_stem(file_name)
    base = file_name.to_s.downcase.sub(/\.[a-z0-9]+\z/, "").tr("_", " ")
    base = base.gsub(/\(.+?\)/, " ")                                        # strip "(cropped)" etc.
    base = base.gsub(/(?<!\d)\d{3,4}(?!\d)/) { |n| n.to_i.between?(1900, 2099) ? n : "NNNN" }
    base = base.gsub(/\s+\d{1,2}\s*\z/, "")                                 # strip trailing "_5"/"_9"
    base.squeeze(" ").strip
  end
end
