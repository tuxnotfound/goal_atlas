# Fills the WC2026 Round-of-32 placeholder matches with the teams that would
# qualify given the group standings *as they stand right now*. Re-runnable: it
# recomputes from current results every time, so it can be run repeatedly as the
# group stage plays out.
#
#   Wc2026BracketPopulator.call   # => { filled: 16, cleared: 0, ... }
#
# Resolves each R32 side's source label against current standings:
#   "1X"      -> group X winner          "2X" -> group X runner-up
#   "3<set>"  -> the third-placed team allocated to this match (FIFA table)
# Later rounds (sources "W##"/"L##") are left untouched until winners exist;
# advancing knockout winners is a separate, post-match concern.
class Wc2026BracketPopulator
  POSITION = /\A([12])([A-L])\z/
  THIRD    = /\A3[A-L]+\z/

  def self.call
    new.call
  end

  def initialize
    @tournament = Tournament.kept.find_by!(year: 2026)
  end

  def call
    standings = GroupStandings.call(group_matches)

    winners = {}
    runners = {}
    thirds  = []

    standings.each do |letter, rows|
      winners[letter] = rows[0]&.dig(:team)
      runners[letter] = rows[1]&.dig(:team)
      thirds << { letter: letter, row: rows[2] } if rows[2]
    end

    # The 8 best third-placed teams, ranked by the same key as intra-group order.
    best_thirds = thirds.sort_by { |t| GroupStandings.sort_key(t[:row], t[:letter]) }.first(8)
    third_by_letter = best_thirds.to_h { |t| [t[:letter], t[:row][:team]] }
    allocation = if best_thirds.size == 8
                   Wc2026::ThirdPlaceAllocation.for(best_thirds.map { |t| t[:letter] })
                 end

    stats = { filled: 0, cleared: 0, unchanged: 0 }

    round_of_32.each do |match|
      home = resolve(match.home_source_label, match.match_number, winners, runners, allocation, third_by_letter)
      away = resolve(match.away_source_label, match.match_number, winners, runners, allocation, third_by_letter)

      changed = match.home_team_id != home&.id || match.away_team_id != away&.id
      next (stats[:unchanged] += 1) unless changed

      match.update!(home_team: home, away_team: away)
      if home && away
        stats[:filled] += 1
      else
        stats[:cleared] += 1
      end
    end

    stats
  end

  private

  def resolve(label, match_number, winners, runners, allocation, third_by_letter)
    case label
    when POSITION
      ($1 == "1" ? winners : runners)[$2]
    when THIRD
      return nil unless allocation
      third_by_letter[allocation[match_number]]
    end
    # "W##"/"L##" and anything else -> nil (not decided yet)
  end

  def group_matches
    @group_matches ||= Match.kept.where(tournament: @tournament, stage: :group_stage)
                            .includes(:home_team, :away_team).to_a
  end

  def round_of_32
    Match.kept.where(tournament: @tournament, stage: :round_of_32).order(:match_number)
  end
end
