# Computes group-stage standings from a set of matches, ranked within each group
# by points, then goal difference, then goals for, then team name.
#
# Returns { "A" => [row, row, ...], "B" => [...], ... } ordered by group letter,
# where each row is { team:, p:, w:, d:, l:, gf:, ga:, pts: }. Scheduled (unplayed)
# matches still register their teams so the group is fully listed, but contribute
# nothing to W/D/L/GF/GA/Pts.
#
# Shared by TournamentsController (which layers an :advanced flag on top) and
# Wc2026BracketPopulator (which reads off the 1st/2nd/3rd placed teams).
class GroupStandings
  def self.call(matches)
    new(matches).call
  end

  def initialize(matches)
    @matches = matches
  end

  def call
    groups = Hash.new { |h, k| h[k] = {} }

    @matches.each do |match|
      letter = match.group_letter.to_s

      [[match.home_team, match.home_score, match.away_score],
       [match.away_team, match.away_score, match.home_score]].each do |team, gf, ga|
        next if team.nil?

        row = (groups[letter][team.id] ||= {
          team: team, p: 0, w: 0, d: 0, l: 0, gf: 0, ga: 0, pts: 0
        })

        next if match.scheduled?

        row[:p]  += 1
        row[:gf] += gf
        row[:ga] += ga

        if match.winner_team_id == team.id
          row[:w]   += 1
          row[:pts] += 3
        elsif match.winner_team_id.present?
          row[:l] += 1
        else
          row[:d]   += 1
          row[:pts] += 1
        end
      end
    end

    groups.transform_values { |rows| rows.values.sort_by { |r| self.class.sort_key(r) } }
          .sort.to_h
  end

  # Ranking key reused for both intra-group order and the best-third comparison.
  def self.sort_key(row, tiebreak = nil)
    [-row[:pts], -(row[:gf] - row[:ga]), -row[:gf], tiebreak || row[:team].name]
  end
end
