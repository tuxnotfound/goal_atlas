# Goals scored across the 8 knockout-stage matches of the 2022 World Cup.
#
# Goal-ordering convention:
#   - minute / stoppage_time match the clock at which the goal was credited
#     (e.g. 90+11 for Weghorst's late equaliser is minute: 90, stoppage_time: 11)
#   - period determines first_half / second_half / extra_time_first / extra_time_second
#   - score_after_goal_home / _away are the cumulative match score after the goal
#
# Depends on: matches.rb, players.rb, teams.rb

tournament = Tournament.find_by!(year: 2022)

def player!(name) = Player.find_by!(name: name)
def t!(code)      = Team.find_by!(fifa_code: code)

def match!(tournament, number) = Match.find_by!(tournament: tournament, match_number: number)

GOALS_2022_KO = [
  # Match 57 — Netherlands 2-2 Argentina (Argentina win 4-3 on pens)
  { match: 57, player: "Nahuel Molina",   team: "ARG", minute: 35, period: :first_half,  type: :open_play,  score: [0, 1] },
  { match: 57, player: "Lionel Messi",    team: "ARG", minute: 73, period: :second_half, type: :penalty,    body: :left_foot, score: [0, 2] },
  { match: 57, player: "Wout Weghorst",   team: "NED", minute: 83, period: :second_half, type: :open_play,  score: [1, 2] },
  { match: 57, player: "Wout Weghorst",   team: "NED", minute: 90, stoppage: 11, period: :second_half, type: :free_kick, score: [2, 2] },

  # Match 58 — Croatia 1-1 Brazil (Croatia win 4-2 on pens)
  { match: 58, player: "Neymar",          team: "BRA", minute: 105, stoppage: 1, period: :extra_time_first,  type: :open_play, score: [0, 1] },
  { match: 58, player: "Bruno Petković",  team: "CRO", minute: 117, stoppage: 3, period: :extra_time_second, type: :open_play, score: [1, 1] },

  # Match 59 — Morocco 1-0 Portugal
  { match: 59, player: "Youssef En-Nesyri", team: "MAR", minute: 42, period: :first_half, type: :open_play, body: :head, score: [1, 0] },

  # Match 60 — England 1-2 France
  { match: 60, player: "Aurélien Tchouaméni", team: "FRA", minute: 17, period: :first_half,  type: :open_play, body: :right_foot, score: [0, 1] },
  { match: 60, player: "Harry Kane",          team: "ENG", minute: 54, period: :second_half, type: :penalty,   body: :right_foot, score: [1, 1] },
  { match: 60, player: "Olivier Giroud",      team: "FRA", minute: 78, period: :second_half, type: :open_play, body: :head, score: [1, 2] },

  # Match 61 — Argentina 3-0 Croatia
  { match: 61, player: "Lionel Messi",   team: "ARG", minute: 34, period: :first_half,  type: :penalty,   body: :left_foot, score: [1, 0] },
  { match: 61, player: "Julián Álvarez", team: "ARG", minute: 39, period: :first_half,  type: :open_play, score: [2, 0] },
  { match: 61, player: "Julián Álvarez", team: "ARG", minute: 69, period: :second_half, type: :open_play, score: [3, 0] },

  # Match 62 — France 2-0 Morocco
  { match: 62, player: "Theo Hernández",   team: "FRA", minute: 5,  period: :first_half,  type: :open_play, body: :left_foot, score: [1, 0] },
  { match: 62, player: "Randal Kolo Muani", team: "FRA", minute: 79, period: :second_half, type: :open_play, score: [2, 0] },

  # Match 63 — Croatia 2-1 Morocco (3rd-place playoff)
  { match: 63, player: "Joško Gvardiol",  team: "CRO", minute: 7,  period: :first_half, type: :open_play, body: :head, score: [1, 0] },
  { match: 63, player: "Achraf Dari",     team: "MAR", minute: 9,  period: :first_half, type: :open_play, body: :head, score: [1, 1] },
  { match: 63, player: "Mislav Oršić",    team: "CRO", minute: 42, period: :first_half, type: :open_play, body: :left_foot, score: [2, 1] },

  # Match 64 — Argentina 3-3 France (Argentina win 4-2 on pens) — THE FINAL
  { match: 64, player: "Lionel Messi",   team: "ARG", minute: 23,  period: :first_half,        type: :penalty,   body: :left_foot,  score: [1, 0] },
  { match: 64, player: "Ángel Di María", team: "ARG", minute: 36,  period: :first_half,        type: :open_play, body: :left_foot,  score: [2, 0] },
  { match: 64, player: "Kylian Mbappé",  team: "FRA", minute: 80,  period: :second_half,       type: :penalty,   body: :right_foot, score: [2, 1] },
  { match: 64, player: "Kylian Mbappé",  team: "FRA", minute: 81,  period: :second_half,       type: :open_play, body: :right_foot, score: [2, 2] },
  { match: 64, player: "Lionel Messi",   team: "ARG", minute: 108, period: :extra_time_first,  type: :open_play, body: :right_foot, score: [3, 2] },
  { match: 64, player: "Kylian Mbappé",  team: "FRA", minute: 118, period: :extra_time_second, type: :penalty,   body: :right_foot, score: [3, 3] }
].freeze

GOALS_2022_KO.each_with_index do |attrs, idx|
  m = match!(tournament, attrs[:match])
  goal = Goal.where(
    match: m,
    player: player!(attrs[:player]),
    minute: attrs[:minute],
    stoppage_time: attrs[:stoppage]
  ).first_or_initialize

  goal.assign_attributes(
    scoring_team: t!(attrs[:team]),
    period: attrs[:period],
    goal_type: attrs[:type],
    body_part: attrs[:body],
    score_after_goal_home: attrs[:score][0],
    score_after_goal_away: attrs[:score][1],
    data_confidence: :verified,
    goal_order: 0
  )
  goal.save!
end

puts "Goals: #{Goal.joins(:match).where(matches: { tournament_id: tournament.id }).count} (target: #{GOALS_2022_KO.size})"
