# All 64 matches of the 2022 FIFA World Cup.
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

MATCHES_2022 = [
  # === GROUP STAGE (Matches 1–48) ===
  # Group A: Qatar, Ecuador, Senegal, Netherlands
  { match_number: 1,  stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 20),
    home: "QAT", away: "ECU", home_score: 0, away_score: 2, winner: "ECU",
    stadium: "Al Bayt Stadium", attendance: 67_372 },
  { match_number: 2,  stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 21),
    home: "SEN", away: "NED", home_score: 0, away_score: 2, winner: "NED",
    stadium: "Al Thumama Stadium", attendance: 41_721 },
  { match_number: 17, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 25),
    home: "QAT", away: "SEN", home_score: 1, away_score: 3, winner: "SEN",
    stadium: "Al Thumama Stadium", attendance: 41_797 },
  { match_number: 18, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 25),
    home: "NED", away: "ECU", home_score: 1, away_score: 1, winner: nil,
    stadium: "Khalifa International Stadium", attendance: 44_833 },
  { match_number: 33, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 29),
    home: "ECU", away: "SEN", home_score: 1, away_score: 2, winner: "SEN",
    stadium: "Khalifa International Stadium", attendance: 44_569 },
  { match_number: 34, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 29),
    home: "NED", away: "QAT", home_score: 2, away_score: 0, winner: "NED",
    stadium: "Al Bayt Stadium", attendance: 66_784 },

  # Group B: England, Iran, USA, Wales
  { match_number: 3,  stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 21),
    home: "ENG", away: "IRN", home_score: 6, away_score: 2, winner: "ENG",
    stadium: "Khalifa International Stadium", attendance: 45_334 },
  { match_number: 4,  stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 21),
    home: "USA", away: "WAL", home_score: 1, away_score: 1, winner: nil,
    stadium: "Ahmad bin Ali Stadium", attendance: 43_418 },
  { match_number: 19, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 25),
    home: "WAL", away: "IRN", home_score: 0, away_score: 2, winner: "IRN",
    stadium: "Ahmad bin Ali Stadium", attendance: 40_875 },
  { match_number: 20, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 25),
    home: "ENG", away: "USA", home_score: 0, away_score: 0, winner: nil,
    stadium: "Al Bayt Stadium", attendance: 68_463 },
  { match_number: 35, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 29),
    home: "WAL", away: "ENG", home_score: 0, away_score: 3, winner: "ENG",
    stadium: "Ahmad bin Ali Stadium", attendance: 44_297 },
  { match_number: 36, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 29),
    home: "IRN", away: "USA", home_score: 0, away_score: 1, winner: "USA",
    stadium: "Al Thumama Stadium", attendance: 42_127 },

  # Group C: Argentina, Saudi Arabia, Mexico, Poland
  { match_number: 7,  stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 22),
    home: "ARG", away: "KSA", home_score: 1, away_score: 2, winner: "KSA",
    stadium: "Lusail Iconic Stadium", attendance: 88_012 },
  { match_number: 8,  stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 22),
    home: "MEX", away: "POL", home_score: 0, away_score: 0, winner: nil,
    stadium: "Stadium 974", attendance: 39_369 },
  { match_number: 21, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 26),
    home: "POL", away: "KSA", home_score: 2, away_score: 0, winner: "POL",
    stadium: "Education City Stadium", attendance: 44_259 },
  { match_number: 22, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 26),
    home: "ARG", away: "MEX", home_score: 2, away_score: 0, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_966 },
  { match_number: 37, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 30),
    home: "POL", away: "ARG", home_score: 0, away_score: 2, winner: "ARG",
    stadium: "Stadium 974", attendance: 44_322 },
  { match_number: 38, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 30),
    home: "KSA", away: "MEX", home_score: 1, away_score: 2, winner: "MEX",
    stadium: "Lusail Iconic Stadium", attendance: 84_985 },

  # Group D: France, Australia, Denmark, Tunisia
  { match_number: 5,  stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 22),
    home: "DEN", away: "TUN", home_score: 0, away_score: 0, winner: nil,
    stadium: "Education City Stadium", attendance: 42_925 },
  { match_number: 9,  stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 22),
    home: "FRA", away: "AUS", home_score: 4, away_score: 1, winner: "FRA",
    stadium: "Al Janoub Stadium", attendance: 40_875 },
  { match_number: 23, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 26),
    home: "TUN", away: "AUS", home_score: 0, away_score: 1, winner: "AUS",
    stadium: "Al Janoub Stadium", attendance: 41_823 },
  { match_number: 24, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 26),
    home: "FRA", away: "DEN", home_score: 2, away_score: 1, winner: "FRA",
    stadium: "Stadium 974", attendance: 42_860 },
  { match_number: 39, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 30),
    home: "TUN", away: "FRA", home_score: 1, away_score: 0, winner: "TUN",
    stadium: "Education City Stadium", attendance: 43_443 },
  { match_number: 40, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 30),
    home: "AUS", away: "DEN", home_score: 1, away_score: 0, winner: "AUS",
    stadium: "Al Janoub Stadium", attendance: 41_232 },

  # Group E: Spain, Costa Rica, Germany, Japan
  { match_number: 11, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 23),
    home: "GER", away: "JPN", home_score: 1, away_score: 2, winner: "JPN",
    stadium: "Khalifa International Stadium", attendance: 42_608 },
  { match_number: 12, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 23),
    home: "ESP", away: "CRC", home_score: 7, away_score: 0, winner: "ESP",
    stadium: "Al Thumama Stadium", attendance: 40_013 },
  { match_number: 25, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 27),
    home: "JPN", away: "CRC", home_score: 0, away_score: 1, winner: "CRC",
    stadium: "Ahmad bin Ali Stadium", attendance: 41_479 },
  { match_number: 26, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 27),
    home: "ESP", away: "GER", home_score: 1, away_score: 1, winner: nil,
    stadium: "Al Bayt Stadium", attendance: 68_895 },
  { match_number: 41, stage: :group_stage, group_letter: "E", date: Date.new(2022, 12, 1),
    home: "JPN", away: "ESP", home_score: 2, away_score: 1, winner: "JPN",
    stadium: "Khalifa International Stadium", attendance: 44_851 },
  { match_number: 42, stage: :group_stage, group_letter: "E", date: Date.new(2022, 12, 1),
    home: "CRC", away: "GER", home_score: 2, away_score: 4, winner: "GER",
    stadium: "Al Bayt Stadium", attendance: 67_054 },

  # Group F: Belgium, Canada, Morocco, Croatia
  { match_number: 10, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 23),
    home: "MAR", away: "CRO", home_score: 0, away_score: 0, winner: nil,
    stadium: "Al Bayt Stadium", attendance: 59_407 },
  { match_number: 13, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 23),
    home: "BEL", away: "CAN", home_score: 1, away_score: 0, winner: "BEL",
    stadium: "Ahmad bin Ali Stadium", attendance: 40_432 },
  { match_number: 27, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 27),
    home: "BEL", away: "MAR", home_score: 0, away_score: 2, winner: "MAR",
    stadium: "Al Thumama Stadium", attendance: 43_738 },
  { match_number: 28, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 27),
    home: "CRO", away: "CAN", home_score: 4, away_score: 1, winner: "CRO",
    stadium: "Khalifa International Stadium", attendance: 44_374 },
  { match_number: 43, stage: :group_stage, group_letter: "F", date: Date.new(2022, 12, 1),
    home: "CRO", away: "BEL", home_score: 0, away_score: 0, winner: nil,
    stadium: "Ahmad bin Ali Stadium", attendance: 43_984 },
  { match_number: 44, stage: :group_stage, group_letter: "F", date: Date.new(2022, 12, 1),
    home: "CAN", away: "MAR", home_score: 1, away_score: 2, winner: "MAR",
    stadium: "Al Thumama Stadium", attendance: 43_102 },

  # Group G: Brazil, Serbia, Switzerland, Cameroon
  { match_number: 14, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 24),
    home: "SUI", away: "CMR", home_score: 1, away_score: 0, winner: "SUI",
    stadium: "Al Janoub Stadium", attendance: 39_089 },
  { match_number: 15, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 24),
    home: "BRA", away: "SRB", home_score: 2, away_score: 0, winner: "BRA",
    stadium: "Lusail Iconic Stadium", attendance: 88_103 },
  { match_number: 29, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 28),
    home: "CMR", away: "SRB", home_score: 3, away_score: 3, winner: nil,
    stadium: "Al Janoub Stadium", attendance: 39_789 },
  { match_number: 30, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 28),
    home: "BRA", away: "SUI", home_score: 1, away_score: 0, winner: "BRA",
    stadium: "Stadium 974", attendance: 43_649 },
  { match_number: 45, stage: :group_stage, group_letter: "G", date: Date.new(2022, 12, 2),
    home: "SRB", away: "SUI", home_score: 2, away_score: 3, winner: "SUI",
    stadium: "Stadium 974", attendance: 41_378 },
  { match_number: 46, stage: :group_stage, group_letter: "G", date: Date.new(2022, 12, 2),
    home: "CMR", away: "BRA", home_score: 1, away_score: 0, winner: "CMR",
    stadium: "Lusail Iconic Stadium", attendance: 85_986 },

  # Group H: Portugal, Ghana, Uruguay, South Korea
  { match_number: 6,  stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 24),
    home: "URU", away: "KOR", home_score: 0, away_score: 0, winner: nil,
    stadium: "Education City Stadium", attendance: 41_663 },
  { match_number: 16, stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 24),
    home: "POR", away: "GHA", home_score: 3, away_score: 2, winner: "POR",
    stadium: "Stadium 974", attendance: 42_662 },
  { match_number: 31, stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 28),
    home: "KOR", away: "GHA", home_score: 2, away_score: 3, winner: "GHA",
    stadium: "Education City Stadium", attendance: 43_983 },
  { match_number: 32, stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 28),
    home: "POR", away: "URU", home_score: 2, away_score: 0, winner: "POR",
    stadium: "Lusail Iconic Stadium", attendance: 88_668 },
  { match_number: 47, stage: :group_stage, group_letter: "H", date: Date.new(2022, 12, 2),
    home: "KOR", away: "POR", home_score: 2, away_score: 1, winner: "KOR",
    stadium: "Education City Stadium", attendance: 44_097 },
  { match_number: 48, stage: :group_stage, group_letter: "H", date: Date.new(2022, 12, 2),
    home: "GHA", away: "URU", home_score: 0, away_score: 2, winner: "URU",
    stadium: "Al Janoub Stadium", attendance: 43_443 },

  # === ROUND OF 16 (Matches 49–56) ===
  { match_number: 49, stage: :round_of_16, date: Date.new(2022, 12, 3),
    home: "NED", away: "USA", home_score: 3, away_score: 1, winner: "NED",
    stadium: "Khalifa International Stadium", attendance: 44_846 },
  { match_number: 50, stage: :round_of_16, date: Date.new(2022, 12, 3),
    home: "ARG", away: "AUS", home_score: 2, away_score: 1, winner: "ARG",
    stadium: "Ahmad bin Ali Stadium", attendance: 45_032 },
  { match_number: 51, stage: :round_of_16, date: Date.new(2022, 12, 4),
    home: "FRA", away: "POL", home_score: 3, away_score: 1, winner: "FRA",
    stadium: "Al Thumama Stadium", attendance: 40_989 },
  { match_number: 52, stage: :round_of_16, date: Date.new(2022, 12, 4),
    home: "ENG", away: "SEN", home_score: 3, away_score: 0, winner: "ENG",
    stadium: "Al Bayt Stadium", attendance: 65_985 },
  { match_number: 53, stage: :round_of_16, date: Date.new(2022, 12, 5),
    home: "JPN", away: "CRO",
    home_score: 1, away_score: 1,
    home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 1, away_penalties: 3,
    result_type: :after_penalties, winner: "CRO",
    stadium: "Al Janoub Stadium", attendance: 42_523 },
  { match_number: 54, stage: :round_of_16, date: Date.new(2022, 12, 5),
    home: "BRA", away: "KOR", home_score: 4, away_score: 1, winner: "BRA",
    stadium: "Stadium 974", attendance: 43_847 },
  { match_number: 55, stage: :round_of_16, date: Date.new(2022, 12, 6),
    home: "MAR", away: "ESP",
    home_score: 0, away_score: 0,
    home_score_after_extra_time: 0, away_score_after_extra_time: 0,
    home_penalties: 3, away_penalties: 0,
    result_type: :after_penalties, winner: "MAR",
    stadium: "Education City Stadium", attendance: 44_667 },
  { match_number: 56, stage: :round_of_16, date: Date.new(2022, 12, 6),
    home: "POR", away: "SUI", home_score: 6, away_score: 1, winner: "POR",
    stadium: "Lusail Iconic Stadium", attendance: 83_720 },

  # === QUARTER-FINALS (Matches 57–60) ===
  { match_number: 57, stage: :quarter_final, date: Date.new(2022, 12, 9),
    home: "NED", away: "ARG",
    home_score: 2, away_score: 2,
    home_score_after_extra_time: 2, away_score_after_extra_time: 2,
    home_penalties: 3, away_penalties: 4,
    result_type: :after_penalties, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_235,
    data_confidence: :verified },
  { match_number: 58, stage: :quarter_final, date: Date.new(2022, 12, 9),
    home: "CRO", away: "BRA",
    home_score: 0, away_score: 0,
    home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 4, away_penalties: 2,
    result_type: :after_penalties, winner: "CRO",
    stadium: "Education City Stadium", attendance: 43_893,
    data_confidence: :verified },
  { match_number: 59, stage: :quarter_final, date: Date.new(2022, 12, 10),
    home: "MAR", away: "POR",
    home_score: 1, away_score: 0,
    result_type: :regulation, winner: "MAR",
    stadium: "Al Thumama Stadium", attendance: 44_198,
    data_confidence: :verified },
  { match_number: 60, stage: :quarter_final, date: Date.new(2022, 12, 10),
    home: "ENG", away: "FRA",
    home_score: 1, away_score: 2,
    result_type: :regulation, winner: "FRA",
    stadium: "Al Bayt Stadium", attendance: 68_895,
    data_confidence: :verified },

  # === SEMI-FINALS (Matches 61–62) ===
  { match_number: 61, stage: :semi_final, date: Date.new(2022, 12, 13),
    home: "ARG", away: "CRO", home_score: 3, away_score: 0,
    result_type: :regulation, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_966,
    data_confidence: :verified },
  { match_number: 62, stage: :semi_final, date: Date.new(2022, 12, 14),
    home: "FRA", away: "MAR", home_score: 2, away_score: 0,
    result_type: :regulation, winner: "FRA",
    stadium: "Al Bayt Stadium", attendance: 68_294,
    data_confidence: :verified },

  # === THIRD-PLACE PLAYOFF (Match 63) ===
  { match_number: 63, stage: :third_place_playoff, date: Date.new(2022, 12, 17),
    home: "CRO", away: "MAR", home_score: 2, away_score: 1,
    result_type: :regulation, winner: "CRO",
    stadium: "Khalifa International Stadium", attendance: 44_137,
    data_confidence: :verified },

  # === FINAL (Match 64) ===
  { match_number: 64, stage: :final, date: Date.new(2022, 12, 18),
    home: "ARG", away: "FRA",
    home_score: 2, away_score: 2,
    home_score_after_extra_time: 3, away_score_after_extra_time: 3,
    home_penalties: 4, away_penalties: 2,
    result_type: :after_penalties, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_966,
    data_confidence: :verified }
].freeze

MATCHES_2022.each do |attrs|
  Match.find_or_create_by!(tournament: tournament, match_number: attrs[:match_number]) do |m|
    m.stage         = attrs[:stage]
    m.date          = attrs[:date]
    m.group_letter  = attrs[:group_letter]
    m.home_team     = t!(attrs[:home])
    m.away_team     = t!(attrs[:away])
    m.home_score    = attrs[:home_score]
    m.away_score    = attrs[:away_score]
    m.home_score_after_extra_time = attrs[:home_score_after_extra_time]
    m.away_score_after_extra_time = attrs[:away_score_after_extra_time]
    m.home_penalties = attrs[:home_penalties]
    m.away_penalties = attrs[:away_penalties]
    m.result_type   = attrs[:result_type] || :regulation
    m.winner_team   = attrs[:winner] ? t!(attrs[:winner]) : nil
    m.stadium       = s!(attrs[:stadium])
    m.attendance    = attrs[:attendance]
    m.data_confidence = attrs[:data_confidence] || :likely
  end
end

puts "Matches: #{Match.where(tournament: tournament).count} for #{tournament.name} (target: 64)"
