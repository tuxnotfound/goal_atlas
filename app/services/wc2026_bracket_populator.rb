# Fills the WC2026 knockout placeholder matches with the teams implied by the
# results so far, then advances winners through the bracket. Re-runnable: it
# recomputes from current data every time, so it can be run repeatedly as the
# tournament plays out (it's invoked automatically after each result sync).
#
#   Wc2026BracketPopulator.call   # => { changed: 3, filled: 17, total: 32 }
#
# Resolves each side's source label against the current state:
#   "1X" / "2X" -> group X winner / runner-up   (from live group standings)
#   "3<set>"    -> the third-placed team allocated to this match (FIFA table)
#   "W##"       -> the winner of match ## once it's decided
#   "L##"       -> the loser of match ## once it's decided (third-place playoff)
# A side stays nil (rendered as its source label, e.g. "Winner Match 73") until
# the match it depends on is decided, so a team takes its place as soon as its
# own game finishes — even while its next opponent is still TBD.
class Wc2026BracketPopulator
  POSITION = /\A([12])([A-L])\z/
  THIRD    = /\A3[A-L]+\z/
  WINNER   = /\AW(\d+)\z/
  LOSER    = /\AL(\d+)\z/

  def self.call
    new.call
  end

  def initialize
    @tournament = Tournament.kept.find_by!(year: 2026)
  end

  def call
    @by_number = knockout_matches.index_by(&:match_number)
    compute_group_resolutions

    stats = { changed: 0 }

    # Ascending match order so a freshly-decided earlier match feeds the later
    # one within the same pass (e.g. a same-day R32 result into its R16 slot).
    @by_number.values.sort_by(&:match_number).each do |match|
      home = resolve(match.home_source_label, match.match_number)
      away = resolve(match.away_source_label, match.match_number)

      next unless match.home_team_id != home&.id || match.away_team_id != away&.id

      match.update!(home_team: home, away_team: away)
      stats[:changed] += 1
    end

    stats[:filled] = @by_number.values.count { |m| m.home_team_id && m.away_team_id }
    stats[:total]  = @by_number.size
    stats
  end

  private

  # Group winners/runners-up and the FIFA-allocated best-eight third places.
  def compute_group_resolutions
    standings = GroupStandings.call(group_matches)

    @winners = {}
    @runners = {}
    thirds   = []

    standings.each do |letter, rows|
      @winners[letter] = rows[0]&.dig(:team)
      @runners[letter] = rows[1]&.dig(:team)
      thirds << { letter: letter, row: rows[2] } if rows[2]
    end

    best = thirds.sort_by { |t| GroupStandings.sort_key(t[:row], t[:letter]) }.first(8)
    @third_by_letter = best.to_h { |t| [t[:letter], t[:row][:team]] }
    @allocation = (Wc2026::ThirdPlaceAllocation.for(best.map { |t| t[:letter] }) if best.size == 8)
  end

  def resolve(label, match_number)
    case label
    when POSITION then ($1 == "1" ? @winners : @runners)[$2]
    when THIRD    then @allocation && @third_by_letter[@allocation[match_number]]
    when WINNER   then winner_of(@by_number[$1.to_i])
    when LOSER    then loser_of(@by_number[$1.to_i])
    end
  end

  def winner_of(match)
    match&.winner_team_id ? match.winner_team : nil
  end

  def loser_of(match)
    return nil unless match&.winner_team_id && match.home_team_id && match.away_team_id
    match.winner_team_id == match.home_team_id ? match.away_team : match.home_team
  end

  def group_matches
    @group_matches ||= Match.kept.where(tournament: @tournament, stage: :group_stage)
                            .includes(:home_team, :away_team).to_a
  end

  def knockout_matches
    Match.kept.where(tournament: @tournament, stage: Match::KNOCKOUT_STAGES)
         .includes(:home_team, :away_team, :winner_team).to_a
  end
end
