# Fills in a tournament's summary row once every one of its matches has been
# played: the final standings (champion, runner-up, third, fourth) and the
# headline totals (matches played, goals scored). These are the numbers the
# tournaments index card and the tournament hero read from, and for historic
# editions they were hand-entered in db/seeds/tournaments.rb — a live edition
# like 2026 has no such seed, so it derives them from its own results instead.
#
#   TournamentFinalizer.call(Tournament.find_by(year: 2026))
#
# Refuses to act until the tournament is complete. A half-played edition would
# otherwise publish a champion the moment the final whistle blew on one match,
# or advertise a partial goal count next to the full 104-match schedule.
#
# Standings come from the bracket, not from a table:
#   1st/2nd — the Final's winner and loser
#   3rd/4th — the third-place playoff's winner and loser
# Editions without a third-place playoff (or without a final at all — 1950's
# round-robin) simply leave those slots untouched, so this never overwrites a
# seeded value with nil.
#
# Goals are summed from the authoritative match scores rather than counted from
# Goal rows: extra-time-aware, and correct even where a match's goal timeline
# isn't fully recorded. Penalty shootouts are excluded, matching FIFA's count.
class TournamentFinalizer
  Result = Struct.new(:changed, :complete, :attributes, keyword_init: true)

  def self.call(tournament) = new(tournament).call

  def initialize(tournament)
    @tournament = tournament
  end

  # Returns a Result: `complete` is false (and nothing is written) while any
  # fixture is still unplayed; `changed` lists the attributes actually updated.
  def call
    return Result.new(changed: [], complete: false, attributes: {}) unless complete?

    attributes = derived_attributes
    changed    = attributes.reject { |key, value| tournament.public_send(key) == value }

    tournament.update!(changed) if changed.any?

    Result.new(changed: changed.keys, complete: true, attributes: attributes)
  end

  private

  attr_reader :tournament

  # Every fixture on the schedule has a result. An edition with no matches at
  # all isn't "complete" — it just hasn't been seeded yet.
  def complete?
    matches.any? && matches.none? { |m| m.scheduled? }
  end

  def derived_attributes
    {
      winner_team_id:       final&.winner_team_id,
      runner_up_team_id:    loser_of(final),
      third_place_team_id:  third_place_playoff&.winner_team_id,
      fourth_place_team_id: loser_of(third_place_playoff),
      total_matches:        matches.size,
      total_goals:          total_goals
    }.compact
  end

  # The side of a decided match that didn't win it. Nil for a match we don't
  # have (no third-place playoff) or one with no winner recorded (a drawn
  # final still awaiting its replay, e.g. pre-shootout editions).
  def loser_of(match)
    return nil unless match&.winner_team_id

    match.winner_team_id == match.home_team_id ? match.away_team_id : match.home_team_id
  end

  # Extra-time scores are cumulative (they include the 90-minute goals), so
  # they replace rather than add to the regulation score where present.
  def total_goals
    matches.sum do |m|
      (m.home_score_after_extra_time || m.home_score).to_i +
        (m.away_score_after_extra_time || m.away_score).to_i
    end
  end

  def final = single_match("final")

  def third_place_playoff = single_match("third_place_playoff")

  # Replays make a stage's match list ambiguous; the later game is the one that
  # settled it (1934's 1-1 final had no replay, but 1962's playoff-era editions
  # and the 1938 knockout rounds did).
  def single_match(stage) = matches.select { |m| m.stage == stage }.max_by(&:date)

  def matches
    @matches ||= tournament.matches.kept.to_a
  end
end
