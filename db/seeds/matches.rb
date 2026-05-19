# 8 knockout-stage matches from the 2022 FIFA World Cup: QF, SF, 3rd-place, final.
# `home_team` is the first-listed team in FIFA's official match record.
# Score fields follow the schema convention:
#   home_score / away_score                       — score at end of regulation (90' + injury time)
#   home_score_after_extra_time / away_score_*    — cumulative after ET (nil if no ET played)
#   home_penalties / away_penalties               — shootout result (nil if no shootout)
#
# Depends on: tournaments.rb, teams.rb, stadiums.rb

tournament = Tournament.find_by!(year: 2022)

def t!(code) = Team.find_by!(fifa_code: code)
def s!(name) = Stadium.find_by!(name: name)

MATCHES_2022_KO = [
  {
    match_number: 57, stage: :quarter_final, date: Date.new(2022, 12, 9),
    home: "NED", away: "ARG",
    home_score: 2, away_score: 2,
    home_score_after_extra_time: 2, away_score_after_extra_time: 2,
    home_penalties: 3, away_penalties: 4,
    result_type: :after_penalties, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_235,
    data_confidence: :verified
  },
  {
    match_number: 58, stage: :quarter_final, date: Date.new(2022, 12, 9),
    home: "CRO", away: "BRA",
    home_score: 0, away_score: 0,
    home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 4, away_penalties: 2,
    result_type: :after_penalties, winner: "CRO",
    stadium: "Education City Stadium", attendance: 43_893,
    data_confidence: :verified
  },
  {
    match_number: 59, stage: :quarter_final, date: Date.new(2022, 12, 10),
    home: "MAR", away: "POR",
    home_score: 1, away_score: 0,
    result_type: :regulation, winner: "MAR",
    stadium: "Al Thumama Stadium", attendance: 44_198,
    data_confidence: :verified
  },
  {
    match_number: 60, stage: :quarter_final, date: Date.new(2022, 12, 10),
    home: "ENG", away: "FRA",
    home_score: 1, away_score: 2,
    result_type: :regulation, winner: "FRA",
    stadium: "Al Bayt Stadium", attendance: 68_895,
    data_confidence: :verified
  },
  {
    match_number: 61, stage: :semi_final, date: Date.new(2022, 12, 13),
    home: "ARG", away: "CRO",
    home_score: 3, away_score: 0,
    result_type: :regulation, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_966,
    data_confidence: :verified
  },
  {
    match_number: 62, stage: :semi_final, date: Date.new(2022, 12, 14),
    home: "FRA", away: "MAR",
    home_score: 2, away_score: 0,
    result_type: :regulation, winner: "FRA",
    stadium: "Al Bayt Stadium", attendance: 68_294,
    data_confidence: :verified
  },
  {
    match_number: 63, stage: :third_place_playoff, date: Date.new(2022, 12, 17),
    home: "CRO", away: "MAR",
    home_score: 2, away_score: 1,
    result_type: :regulation, winner: "CRO",
    stadium: "Khalifa International Stadium", attendance: 44_137,
    data_confidence: :verified
  },
  {
    match_number: 64, stage: :final, date: Date.new(2022, 12, 18),
    home: "ARG", away: "FRA",
    home_score: 2, away_score: 2,
    home_score_after_extra_time: 3, away_score_after_extra_time: 3,
    home_penalties: 4, away_penalties: 2,
    result_type: :after_penalties, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_966,
    data_confidence: :verified
  }
].freeze

MATCHES_2022_KO.each do |attrs|
  Match.find_or_create_by!(tournament: tournament, match_number: attrs[:match_number]) do |m|
    m.stage         = attrs[:stage]
    m.date          = attrs[:date]
    m.home_team     = t!(attrs[:home])
    m.away_team     = t!(attrs[:away])
    m.home_score    = attrs[:home_score]
    m.away_score    = attrs[:away_score]
    m.home_score_after_extra_time = attrs[:home_score_after_extra_time]
    m.away_score_after_extra_time = attrs[:away_score_after_extra_time]
    m.home_penalties = attrs[:home_penalties]
    m.away_penalties = attrs[:away_penalties]
    m.result_type   = attrs[:result_type]
    m.winner_team   = attrs[:winner] ? t!(attrs[:winner]) : nil
    m.stadium       = s!(attrs[:stadium])
    m.attendance    = attrs[:attendance]
    m.data_confidence = attrs[:data_confidence]
  end
end

puts "Matches: #{Match.where(tournament: tournament).count} for #{tournament.name} (target: 8 KO)"
