# All matches across the seeded FIFA World Cup tournaments.
# `home_team` is the first-listed team in FIFA's official match record.
# Score fields follow the schema convention:
#   home_score / away_score                       — score at end of regulation (90' + injury time)
#   home_score_after_extra_time / away_score_*    — cumulative after ET (nil if no ET played)
#   home_penalties / away_penalties               — shootout result (nil if no shootout)
#
# Depends on: tournaments.rb, teams.rb, stadiums.rb

def t!(code) = Team.find_by!(fifa_code: code)
def s!(name) = Stadium.find_by!(name: name)

# ============================================================
# 1986 (Mexico) — 52 matches
# ============================================================
MATCHES_1986 = [
  # Group A: Italy, Argentina, Bulgaria, South Korea
  { match_number: 1,  stage: :group_stage, group_letter: "A", date: Date.new(1986, 5, 31), home: "ITA", away: "BUL", home_score: 1, away_score: 1, stadium: "Estadio Azteca", attendance: 96_000 },
  { match_number: 2,  stage: :group_stage, group_letter: "A", date: Date.new(1986, 6, 2),  home: "ARG", away: "KOR", home_score: 3, away_score: 1, winner: "ARG", stadium: "Estadio Olímpico Universitario", attendance: 60_000 },
  { match_number: 12, stage: :group_stage, group_letter: "A", date: Date.new(1986, 6, 5),  home: "ITA", away: "ARG", home_score: 1, away_score: 1, stadium: "Estadio Cuauhtémoc", attendance: 32_000 },
  { match_number: 13, stage: :group_stage, group_letter: "A", date: Date.new(1986, 6, 5),  home: "KOR", away: "BUL", home_score: 1, away_score: 1, stadium: "Estadio Olímpico Universitario", attendance: 35_000 },
  { match_number: 22, stage: :group_stage, group_letter: "A", date: Date.new(1986, 6, 10), home: "KOR", away: "ITA", home_score: 2, away_score: 3, winner: "ITA", stadium: "Estadio Cuauhtémoc", attendance: 22_000 },
  { match_number: 23, stage: :group_stage, group_letter: "A", date: Date.new(1986, 6, 10), home: "ARG", away: "BUL", home_score: 2, away_score: 0, winner: "ARG", stadium: "Estadio Olímpico Universitario", attendance: 65_000 },

  # Group B: Mexico, Belgium, Paraguay, Iraq
  { match_number: 3,  stage: :group_stage, group_letter: "B", date: Date.new(1986, 6, 3),  home: "MEX", away: "BEL", home_score: 2, away_score: 1, winner: "MEX", stadium: "Estadio Azteca", attendance: 110_000 },
  { match_number: 4,  stage: :group_stage, group_letter: "B", date: Date.new(1986, 6, 4),  home: "PAR", away: "IRQ", home_score: 1, away_score: 0, winner: "PAR", stadium: "Estadio Cuauhtémoc", attendance: 24_000 },
  { match_number: 14, stage: :group_stage, group_letter: "B", date: Date.new(1986, 6, 7),  home: "MEX", away: "PAR", home_score: 1, away_score: 1, stadium: "Estadio Azteca", attendance: 114_000 },
  { match_number: 15, stage: :group_stage, group_letter: "B", date: Date.new(1986, 6, 8),  home: "IRQ", away: "BEL", home_score: 1, away_score: 2, winner: "BEL", stadium: "Estadio Olímpico Universitario", attendance: 22_000 },
  { match_number: 24, stage: :group_stage, group_letter: "B", date: Date.new(1986, 6, 11), home: "PAR", away: "BEL", home_score: 2, away_score: 2, stadium: "Estadio Nemesio Díez", attendance: 28_000 },
  { match_number: 25, stage: :group_stage, group_letter: "B", date: Date.new(1986, 6, 11), home: "IRQ", away: "MEX", home_score: 0, away_score: 1, winner: "MEX", stadium: "Estadio Azteca", attendance: 103_763 },

  # Group C: France, Canada, USSR, Hungary
  { match_number: 5,  stage: :group_stage, group_letter: "C", date: Date.new(1986, 6, 1),  home: "CAN", away: "FRA", home_score: 0, away_score: 1, winner: "FRA", stadium: "Estadio Nou Camp", attendance: 65_500 },
  { match_number: 6,  stage: :group_stage, group_letter: "C", date: Date.new(1986, 6, 2),  home: "URS", away: "HUN", home_score: 6, away_score: 0, winner: "URS", stadium: "Estadio Sergio León Chávez", attendance: 16_000 },
  { match_number: 16, stage: :group_stage, group_letter: "C", date: Date.new(1986, 6, 5),  home: "FRA", away: "URS", home_score: 1, away_score: 1, stadium: "Estadio Nou Camp", attendance: 36_540 },
  { match_number: 17, stage: :group_stage, group_letter: "C", date: Date.new(1986, 6, 6),  home: "HUN", away: "CAN", home_score: 2, away_score: 0, winner: "HUN", stadium: "Estadio Sergio León Chávez", attendance: 13_800 },
  { match_number: 26, stage: :group_stage, group_letter: "C", date: Date.new(1986, 6, 9),  home: "HUN", away: "FRA", home_score: 0, away_score: 3, winner: "FRA", stadium: "Estadio Nou Camp", attendance: 31_420 },
  { match_number: 27, stage: :group_stage, group_letter: "C", date: Date.new(1986, 6, 9),  home: "CAN", away: "URS", home_score: 0, away_score: 2, winner: "URS", stadium: "Estadio Sergio León Chávez", attendance: 14_000 },

  # Group D: Brazil, Spain, Algeria, Northern Ireland
  { match_number: 7,  stage: :group_stage, group_letter: "D", date: Date.new(1986, 6, 1),  home: "ESP", away: "BRA", home_score: 0, away_score: 1, winner: "BRA", stadium: "Estadio Jalisco", attendance: 35_748 },
  { match_number: 8,  stage: :group_stage, group_letter: "D", date: Date.new(1986, 6, 3),  home: "ALG", away: "NIR", home_score: 1, away_score: 1, stadium: "Estadio Tres de Marzo", attendance: 22_000 },
  { match_number: 18, stage: :group_stage, group_letter: "D", date: Date.new(1986, 6, 6),  home: "BRA", away: "ALG", home_score: 1, away_score: 0, winner: "BRA", stadium: "Estadio Jalisco", attendance: 30_000 },
  { match_number: 19, stage: :group_stage, group_letter: "D", date: Date.new(1986, 6, 7),  home: "NIR", away: "ESP", home_score: 1, away_score: 2, winner: "ESP", stadium: "Estadio Tres de Marzo", attendance: 20_000 },
  { match_number: 28, stage: :group_stage, group_letter: "D", date: Date.new(1986, 6, 12), home: "ESP", away: "ALG", home_score: 3, away_score: 0, winner: "ESP", stadium: "Estadio Tecnológico", attendance: 20_000 },
  { match_number: 29, stage: :group_stage, group_letter: "D", date: Date.new(1986, 6, 12), home: "NIR", away: "BRA", home_score: 0, away_score: 3, winner: "BRA", stadium: "Estadio Jalisco", attendance: 51_000 },

  # Group E: West Germany, Uruguay, Scotland, Denmark
  { match_number: 9,  stage: :group_stage, group_letter: "E", date: Date.new(1986, 6, 4),  home: "URU", away: "FRG", home_score: 1, away_score: 1, stadium: "Estadio Corregidora", attendance: 30_500 },
  { match_number: 10, stage: :group_stage, group_letter: "E", date: Date.new(1986, 6, 4),  home: "SCO", away: "DEN", home_score: 0, away_score: 1, winner: "DEN", stadium: "Estadio Neza 86", attendance: 18_000 },
  { match_number: 20, stage: :group_stage, group_letter: "E", date: Date.new(1986, 6, 8),  home: "DEN", away: "URU", home_score: 6, away_score: 1, winner: "DEN", stadium: "Estadio Neza 86", attendance: 26_500 },
  { match_number: 21, stage: :group_stage, group_letter: "E", date: Date.new(1986, 6, 8),  home: "FRG", away: "SCO", home_score: 2, away_score: 1, winner: "FRG", stadium: "Estadio Corregidora", attendance: 30_000 },
  { match_number: 30, stage: :group_stage, group_letter: "E", date: Date.new(1986, 6, 13), home: "SCO", away: "URU", home_score: 0, away_score: 0, stadium: "Estadio Neza 86", attendance: 19_900 },
  { match_number: 31, stage: :group_stage, group_letter: "E", date: Date.new(1986, 6, 13), home: "DEN", away: "FRG", home_score: 2, away_score: 0, winner: "DEN", stadium: "Estadio Corregidora", attendance: 36_000 },

  # Group F: Morocco, Poland, England, Portugal
  { match_number: 11, stage: :group_stage, group_letter: "F", date: Date.new(1986, 6, 2),  home: "POL", away: "MAR", home_score: 0, away_score: 0, stadium: "Estadio Nou Camp", attendance: 19_900 },
  { match_number: 32, stage: :group_stage, group_letter: "F", date: Date.new(1986, 6, 3),  home: "POR", away: "ENG", home_score: 1, away_score: 0, winner: "POR", stadium: "Estadio Tecnológico", attendance: 23_295 },
  { match_number: 33, stage: :group_stage, group_letter: "F", date: Date.new(1986, 6, 6),  home: "POL", away: "POR", home_score: 1, away_score: 0, winner: "POL", stadium: "Estadio Nou Camp", attendance: 19_500 },
  { match_number: 34, stage: :group_stage, group_letter: "F", date: Date.new(1986, 6, 6),  home: "ENG", away: "MAR", home_score: 0, away_score: 0, stadium: "Estadio Tecnológico", attendance: 20_200 },
  { match_number: 35, stage: :group_stage, group_letter: "F", date: Date.new(1986, 6, 11), home: "POR", away: "MAR", home_score: 1, away_score: 3, winner: "MAR", stadium: "Estadio Sergio León Chávez", attendance: 16_000 },
  { match_number: 36, stage: :group_stage, group_letter: "F", date: Date.new(1986, 6, 11), home: "ENG", away: "POL", home_score: 3, away_score: 0, winner: "ENG", stadium: "Estadio Universitario (Monterrey)", attendance: 22_700 },

  # Round of 16
  { match_number: 37, stage: :round_of_16, date: Date.new(1986, 6, 15), home: "MEX", away: "BUL", home_score: 2, away_score: 0, winner: "MEX", stadium: "Estadio Azteca", attendance: 114_580 },
  { match_number: 38, stage: :round_of_16, date: Date.new(1986, 6, 15), home: "URS", away: "BEL", home_score: 3, away_score: 4, home_score_after_extra_time: 3, away_score_after_extra_time: 4, result_type: :after_extra_time, winner: "BEL", stadium: "Estadio Nou Camp", attendance: 32_277 },
  { match_number: 39, stage: :round_of_16, date: Date.new(1986, 6, 16), home: "BRA", away: "POL", home_score: 4, away_score: 0, winner: "BRA", stadium: "Estadio Jalisco", attendance: 45_000 },
  { match_number: 40, stage: :round_of_16, date: Date.new(1986, 6, 16), home: "ARG", away: "URU", home_score: 1, away_score: 0, winner: "ARG", stadium: "Estadio Cuauhtémoc", attendance: 26_000 },
  { match_number: 41, stage: :round_of_16, date: Date.new(1986, 6, 17), home: "FRA", away: "ITA", home_score: 2, away_score: 0, winner: "FRA", stadium: "Estadio Olímpico Universitario", attendance: 70_000 },
  { match_number: 42, stage: :round_of_16, date: Date.new(1986, 6, 17), home: "FRG", away: "MAR", home_score: 1, away_score: 0, winner: "FRG", stadium: "Estadio Universitario (Monterrey)", attendance: 19_800 },
  { match_number: 43, stage: :round_of_16, date: Date.new(1986, 6, 18), home: "ENG", away: "PAR", home_score: 3, away_score: 0, winner: "ENG", stadium: "Estadio Azteca", attendance: 98_728 },
  { match_number: 44, stage: :round_of_16, date: Date.new(1986, 6, 18), home: "ESP", away: "DEN", home_score: 5, away_score: 1, winner: "ESP", stadium: "Estadio Corregidora", attendance: 38_500 },

  # Quarter-finals
  { match_number: 45, stage: :quarter_final, date: Date.new(1986, 6, 21), home: "BRA", away: "FRA",
    home_score: 1, away_score: 1, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 3, away_penalties: 4, result_type: :after_penalties, winner: "FRA",
    stadium: "Estadio Jalisco", attendance: 65_000 },
  { match_number: 46, stage: :quarter_final, date: Date.new(1986, 6, 21), home: "FRG", away: "MEX",
    home_score: 0, away_score: 0, home_score_after_extra_time: 0, away_score_after_extra_time: 0,
    home_penalties: 4, away_penalties: 1, result_type: :after_penalties, winner: "FRG",
    stadium: "Estadio Universitario (Monterrey)", attendance: 41_700 },
  { match_number: 47, stage: :quarter_final, date: Date.new(1986, 6, 22), home: "ARG", away: "ENG",
    home_score: 2, away_score: 1, winner: "ARG",
    stadium: "Estadio Azteca", attendance: 114_580,
    notes: "Hand of God + Goal of the Century (Maradona)" },
  { match_number: 48, stage: :quarter_final, date: Date.new(1986, 6, 22), home: "ESP", away: "BEL",
    home_score: 1, away_score: 1, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 4, away_penalties: 5, result_type: :after_penalties, winner: "BEL",
    stadium: "Estadio Cuauhtémoc", attendance: 45_000 },

  # Semi-finals
  { match_number: 49, stage: :semi_final, date: Date.new(1986, 6, 25), home: "FRA", away: "FRG", home_score: 0, away_score: 2, winner: "FRG", stadium: "Estadio Jalisco", attendance: 45_000 },
  { match_number: 50, stage: :semi_final, date: Date.new(1986, 6, 25), home: "ARG", away: "BEL", home_score: 2, away_score: 0, winner: "ARG", stadium: "Estadio Azteca", attendance: 110_420 },

  # Third-place playoff
  { match_number: 51, stage: :third_place_playoff, date: Date.new(1986, 6, 28),
    home: "FRA", away: "BEL", home_score: 2, away_score: 2,
    home_score_after_extra_time: 4, away_score_after_extra_time: 2,
    result_type: :after_extra_time, winner: "FRA",
    stadium: "Estadio Cuauhtémoc", attendance: 21_500 },

  # Final
  { match_number: 52, stage: :final, date: Date.new(1986, 6, 29),
    home: "ARG", away: "FRG", home_score: 3, away_score: 2, winner: "ARG",
    stadium: "Estadio Azteca", attendance: 114_600 }
].freeze

# ============================================================
# 2018 (Russia) — 64 matches
# ============================================================
MATCHES_2018 = [
  # Group A: Russia, Saudi Arabia, Egypt, Uruguay
  { match_number: 1,  stage: :group_stage, group_letter: "A", date: Date.new(2018, 6, 14), home: "RUS", away: "KSA", home_score: 5, away_score: 0, winner: "RUS", stadium: "Luzhniki Stadium", attendance: 78_011 },
  { match_number: 4,  stage: :group_stage, group_letter: "A", date: Date.new(2018, 6, 15), home: "EGY", away: "URU", home_score: 0, away_score: 1, winner: "URU", stadium: "Ekaterinburg Arena", attendance: 27_015 },
  { match_number: 17, stage: :group_stage, group_letter: "A", date: Date.new(2018, 6, 19), home: "RUS", away: "EGY", home_score: 3, away_score: 1, winner: "RUS", stadium: "Saint Petersburg Stadium", attendance: 64_468 },
  { match_number: 18, stage: :group_stage, group_letter: "A", date: Date.new(2018, 6, 20), home: "URU", away: "KSA", home_score: 1, away_score: 0, winner: "URU", stadium: "Rostov Arena", attendance: 42_678 },
  { match_number: 33, stage: :group_stage, group_letter: "A", date: Date.new(2018, 6, 25), home: "URU", away: "RUS", home_score: 3, away_score: 0, winner: "URU", stadium: "Samara Arena", attendance: 41_970 },
  { match_number: 34, stage: :group_stage, group_letter: "A", date: Date.new(2018, 6, 25), home: "KSA", away: "EGY", home_score: 2, away_score: 1, winner: "KSA", stadium: "Volgograd Arena", attendance: 41_840 },

  # Group B: Portugal, Spain, Morocco, Iran
  { match_number: 2,  stage: :group_stage, group_letter: "B", date: Date.new(2018, 6, 15), home: "MAR", away: "IRN", home_score: 0, away_score: 1, winner: "IRN", stadium: "Saint Petersburg Stadium", attendance: 62_548 },
  { match_number: 3,  stage: :group_stage, group_letter: "B", date: Date.new(2018, 6, 15), home: "POR", away: "ESP", home_score: 3, away_score: 3, stadium: "Fisht Olympic Stadium", attendance: 43_866 },
  { match_number: 19, stage: :group_stage, group_letter: "B", date: Date.new(2018, 6, 20), home: "POR", away: "MAR", home_score: 1, away_score: 0, winner: "POR", stadium: "Luzhniki Stadium", attendance: 78_011 },
  { match_number: 20, stage: :group_stage, group_letter: "B", date: Date.new(2018, 6, 20), home: "IRN", away: "ESP", home_score: 0, away_score: 1, winner: "ESP", stadium: "Kazan Arena", attendance: 42_718 },
  { match_number: 35, stage: :group_stage, group_letter: "B", date: Date.new(2018, 6, 25), home: "IRN", away: "POR", home_score: 1, away_score: 1, stadium: "Mordovia Arena", attendance: 41_685 },
  { match_number: 36, stage: :group_stage, group_letter: "B", date: Date.new(2018, 6, 25), home: "ESP", away: "MAR", home_score: 2, away_score: 2, stadium: "Kaliningrad Stadium", attendance: 33_973 },

  # Group C: France, Australia, Peru, Denmark
  { match_number: 5,  stage: :group_stage, group_letter: "C", date: Date.new(2018, 6, 16), home: "FRA", away: "AUS", home_score: 2, away_score: 1, winner: "FRA", stadium: "Kazan Arena", attendance: 41_279 },
  { match_number: 8,  stage: :group_stage, group_letter: "C", date: Date.new(2018, 6, 16), home: "PER", away: "DEN", home_score: 0, away_score: 1, winner: "DEN", stadium: "Mordovia Arena", attendance: 40_502 },
  { match_number: 21, stage: :group_stage, group_letter: "C", date: Date.new(2018, 6, 21), home: "DEN", away: "AUS", home_score: 1, away_score: 1, stadium: "Samara Arena", attendance: 40_727 },
  { match_number: 22, stage: :group_stage, group_letter: "C", date: Date.new(2018, 6, 21), home: "FRA", away: "PER", home_score: 1, away_score: 0, winner: "FRA", stadium: "Ekaterinburg Arena", attendance: 32_789 },
  { match_number: 37, stage: :group_stage, group_letter: "C", date: Date.new(2018, 6, 26), home: "DEN", away: "FRA", home_score: 0, away_score: 0, stadium: "Luzhniki Stadium", attendance: 78_011 },
  { match_number: 38, stage: :group_stage, group_letter: "C", date: Date.new(2018, 6, 26), home: "AUS", away: "PER", home_score: 0, away_score: 2, winner: "PER", stadium: "Fisht Olympic Stadium", attendance: 44_073 },

  # Group D: Argentina, Iceland, Croatia, Nigeria
  { match_number: 6,  stage: :group_stage, group_letter: "D", date: Date.new(2018, 6, 16), home: "ARG", away: "ISL", home_score: 1, away_score: 1, stadium: "Otkrytie Arena", attendance: 44_190 },
  { match_number: 9,  stage: :group_stage, group_letter: "D", date: Date.new(2018, 6, 16), home: "CRO", away: "NGA", home_score: 2, away_score: 0, winner: "CRO", stadium: "Kaliningrad Stadium", attendance: 31_136 },
  { match_number: 23, stage: :group_stage, group_letter: "D", date: Date.new(2018, 6, 21), home: "ARG", away: "CRO", home_score: 0, away_score: 3, winner: "CRO", stadium: "Nizhny Novgorod Stadium", attendance: 43_319 },
  { match_number: 24, stage: :group_stage, group_letter: "D", date: Date.new(2018, 6, 22), home: "NGA", away: "ISL", home_score: 2, away_score: 0, winner: "NGA", stadium: "Volgograd Arena", attendance: 43_584 },
  { match_number: 39, stage: :group_stage, group_letter: "D", date: Date.new(2018, 6, 26), home: "NGA", away: "ARG", home_score: 1, away_score: 2, winner: "ARG", stadium: "Saint Petersburg Stadium", attendance: 64_468 },
  { match_number: 40, stage: :group_stage, group_letter: "D", date: Date.new(2018, 6, 26), home: "ISL", away: "CRO", home_score: 1, away_score: 2, winner: "CRO", stadium: "Rostov Arena", attendance: 43_472 },

  # Group E: Brazil, Switzerland, Costa Rica, Serbia
  { match_number: 10, stage: :group_stage, group_letter: "E", date: Date.new(2018, 6, 17), home: "CRC", away: "SRB", home_score: 0, away_score: 1, winner: "SRB", stadium: "Samara Arena", attendance: 41_432 },
  { match_number: 11, stage: :group_stage, group_letter: "E", date: Date.new(2018, 6, 17), home: "BRA", away: "SUI", home_score: 1, away_score: 1, stadium: "Rostov Arena", attendance: 43_109 },
  { match_number: 25, stage: :group_stage, group_letter: "E", date: Date.new(2018, 6, 22), home: "BRA", away: "CRC", home_score: 2, away_score: 0, winner: "BRA", stadium: "Saint Petersburg Stadium", attendance: 64_468 },
  { match_number: 26, stage: :group_stage, group_letter: "E", date: Date.new(2018, 6, 22), home: "SRB", away: "SUI", home_score: 1, away_score: 2, winner: "SUI", stadium: "Kaliningrad Stadium", attendance: 33_167 },
  { match_number: 41, stage: :group_stage, group_letter: "E", date: Date.new(2018, 6, 27), home: "SRB", away: "BRA", home_score: 0, away_score: 2, winner: "BRA", stadium: "Otkrytie Arena", attendance: 44_190 },
  { match_number: 42, stage: :group_stage, group_letter: "E", date: Date.new(2018, 6, 27), home: "SUI", away: "CRC", home_score: 2, away_score: 2, stadium: "Nizhny Novgorod Stadium", attendance: 43_319 },

  # Group F: Germany, Mexico, Sweden, South Korea
  { match_number: 12, stage: :group_stage, group_letter: "F", date: Date.new(2018, 6, 17), home: "GER", away: "MEX", home_score: 0, away_score: 1, winner: "MEX", stadium: "Luzhniki Stadium", attendance: 78_011 },
  { match_number: 13, stage: :group_stage, group_letter: "F", date: Date.new(2018, 6, 18), home: "SWE", away: "KOR", home_score: 1, away_score: 0, winner: "SWE", stadium: "Nizhny Novgorod Stadium", attendance: 42_300 },
  { match_number: 27, stage: :group_stage, group_letter: "F", date: Date.new(2018, 6, 23), home: "KOR", away: "MEX", home_score: 1, away_score: 2, winner: "MEX", stadium: "Rostov Arena", attendance: 43_472 },
  { match_number: 28, stage: :group_stage, group_letter: "F", date: Date.new(2018, 6, 23), home: "GER", away: "SWE", home_score: 2, away_score: 1, winner: "GER", stadium: "Fisht Olympic Stadium", attendance: 44_287 },
  { match_number: 43, stage: :group_stage, group_letter: "F", date: Date.new(2018, 6, 27), home: "KOR", away: "GER", home_score: 2, away_score: 0, winner: "KOR", stadium: "Kazan Arena", attendance: 41_835 },
  { match_number: 44, stage: :group_stage, group_letter: "F", date: Date.new(2018, 6, 27), home: "MEX", away: "SWE", home_score: 0, away_score: 3, winner: "SWE", stadium: "Ekaterinburg Arena", attendance: 33_061 },

  # Group G: Belgium, Panama, Tunisia, England
  { match_number: 14, stage: :group_stage, group_letter: "G", date: Date.new(2018, 6, 18), home: "BEL", away: "PAN", home_score: 3, away_score: 0, winner: "BEL", stadium: "Fisht Olympic Stadium", attendance: 43_257 },
  { match_number: 15, stage: :group_stage, group_letter: "G", date: Date.new(2018, 6, 18), home: "TUN", away: "ENG", home_score: 1, away_score: 2, winner: "ENG", stadium: "Volgograd Arena", attendance: 41_064 },
  { match_number: 29, stage: :group_stage, group_letter: "G", date: Date.new(2018, 6, 23), home: "BEL", away: "TUN", home_score: 5, away_score: 2, winner: "BEL", stadium: "Otkrytie Arena", attendance: 44_190 },
  { match_number: 30, stage: :group_stage, group_letter: "G", date: Date.new(2018, 6, 24), home: "ENG", away: "PAN", home_score: 6, away_score: 1, winner: "ENG", stadium: "Nizhny Novgorod Stadium", attendance: 43_319 },
  { match_number: 45, stage: :group_stage, group_letter: "G", date: Date.new(2018, 6, 28), home: "ENG", away: "BEL", home_score: 0, away_score: 1, winner: "BEL", stadium: "Kaliningrad Stadium", attendance: 33_973 },
  { match_number: 46, stage: :group_stage, group_letter: "G", date: Date.new(2018, 6, 28), home: "PAN", away: "TUN", home_score: 1, away_score: 2, winner: "TUN", stadium: "Mordovia Arena", attendance: 44_190 },

  # Group H: Poland, Senegal, Colombia, Japan
  { match_number: 7,  stage: :group_stage, group_letter: "H", date: Date.new(2018, 6, 19), home: "COL", away: "JPN", home_score: 1, away_score: 2, winner: "JPN", stadium: "Mordovia Arena", attendance: 40_842 },
  { match_number: 16, stage: :group_stage, group_letter: "H", date: Date.new(2018, 6, 19), home: "POL", away: "SEN", home_score: 1, away_score: 2, winner: "SEN", stadium: "Otkrytie Arena", attendance: 44_190 },
  { match_number: 31, stage: :group_stage, group_letter: "H", date: Date.new(2018, 6, 24), home: "JPN", away: "SEN", home_score: 2, away_score: 2, stadium: "Ekaterinburg Arena", attendance: 32_205 },
  { match_number: 32, stage: :group_stage, group_letter: "H", date: Date.new(2018, 6, 24), home: "POL", away: "COL", home_score: 0, away_score: 3, winner: "COL", stadium: "Kazan Arena", attendance: 42_873 },
  { match_number: 47, stage: :group_stage, group_letter: "H", date: Date.new(2018, 6, 28), home: "SEN", away: "COL", home_score: 0, away_score: 1, winner: "COL", stadium: "Samara Arena", attendance: 41_970 },
  { match_number: 48, stage: :group_stage, group_letter: "H", date: Date.new(2018, 6, 28), home: "JPN", away: "POL", home_score: 0, away_score: 1, winner: "POL", stadium: "Volgograd Arena", attendance: 42_189 },

  # Round of 16
  { match_number: 49, stage: :round_of_16, date: Date.new(2018, 6, 30), home: "FRA", away: "ARG", home_score: 4, away_score: 3, winner: "FRA", stadium: "Kazan Arena", attendance: 42_873 },
  { match_number: 50, stage: :round_of_16, date: Date.new(2018, 6, 30), home: "URU", away: "POR", home_score: 2, away_score: 1, winner: "URU", stadium: "Fisht Olympic Stadium", attendance: 44_287 },
  { match_number: 51, stage: :round_of_16, date: Date.new(2018, 7, 1), home: "ESP", away: "RUS",
    home_score: 1, away_score: 1, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 3, away_penalties: 4, result_type: :after_penalties, winner: "RUS",
    stadium: "Luzhniki Stadium", attendance: 78_011 },
  { match_number: 52, stage: :round_of_16, date: Date.new(2018, 7, 1), home: "CRO", away: "DEN",
    home_score: 1, away_score: 1, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 3, away_penalties: 2, result_type: :after_penalties, winner: "CRO",
    stadium: "Nizhny Novgorod Stadium", attendance: 43_319 },
  { match_number: 53, stage: :round_of_16, date: Date.new(2018, 7, 2), home: "BRA", away: "MEX", home_score: 2, away_score: 0, winner: "BRA", stadium: "Samara Arena", attendance: 41_970 },
  { match_number: 54, stage: :round_of_16, date: Date.new(2018, 7, 2), home: "BEL", away: "JPN", home_score: 3, away_score: 2, winner: "BEL", stadium: "Rostov Arena", attendance: 41_466 },
  { match_number: 55, stage: :round_of_16, date: Date.new(2018, 7, 3), home: "SWE", away: "SUI", home_score: 1, away_score: 0, winner: "SWE", stadium: "Saint Petersburg Stadium", attendance: 64_042 },
  { match_number: 56, stage: :round_of_16, date: Date.new(2018, 7, 3), home: "COL", away: "ENG",
    home_score: 1, away_score: 1, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 3, away_penalties: 4, result_type: :after_penalties, winner: "ENG",
    stadium: "Otkrytie Arena", attendance: 44_190 },

  # Quarter-finals
  { match_number: 57, stage: :quarter_final, date: Date.new(2018, 7, 6), home: "URU", away: "FRA", home_score: 0, away_score: 2, winner: "FRA", stadium: "Nizhny Novgorod Stadium", attendance: 43_319 },
  { match_number: 58, stage: :quarter_final, date: Date.new(2018, 7, 6), home: "BRA", away: "BEL", home_score: 1, away_score: 2, winner: "BEL", stadium: "Kazan Arena", attendance: 42_873 },
  { match_number: 59, stage: :quarter_final, date: Date.new(2018, 7, 7), home: "SWE", away: "ENG", home_score: 0, away_score: 2, winner: "ENG", stadium: "Samara Arena", attendance: 39_991 },
  { match_number: 60, stage: :quarter_final, date: Date.new(2018, 7, 7), home: "RUS", away: "CRO",
    home_score: 2, away_score: 2, home_score_after_extra_time: 2, away_score_after_extra_time: 2,
    home_penalties: 3, away_penalties: 4, result_type: :after_penalties, winner: "CRO",
    stadium: "Fisht Olympic Stadium", attendance: 44_287 },

  # Semi-finals
  { match_number: 61, stage: :semi_final, date: Date.new(2018, 7, 10), home: "FRA", away: "BEL", home_score: 1, away_score: 0, winner: "FRA", stadium: "Saint Petersburg Stadium", attendance: 64_286 },
  { match_number: 62, stage: :semi_final, date: Date.new(2018, 7, 11), home: "CRO", away: "ENG",
    home_score: 1, away_score: 1, home_score_after_extra_time: 2, away_score_after_extra_time: 1,
    result_type: :after_extra_time, winner: "CRO",
    stadium: "Luzhniki Stadium", attendance: 78_011 },

  # Third-place playoff
  { match_number: 63, stage: :third_place_playoff, date: Date.new(2018, 7, 14), home: "BEL", away: "ENG", home_score: 2, away_score: 0, winner: "BEL", stadium: "Saint Petersburg Stadium", attendance: 64_406 },

  # Final
  { match_number: 64, stage: :final, date: Date.new(2018, 7, 15), home: "FRA", away: "CRO", home_score: 4, away_score: 2, winner: "FRA", stadium: "Luzhniki Stadium", attendance: 78_011 }
].freeze

# ============================================================
# 2022 (Qatar) — 64 matches
# ============================================================
MATCHES_2022 = [
  # Group A: Qatar, Ecuador, Senegal, Netherlands
  { match_number: 1,  stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 20), home: "QAT", away: "ECU", home_score: 0, away_score: 2, winner: "ECU", stadium: "Al Bayt Stadium", attendance: 67_372 },
  { match_number: 2,  stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 21), home: "SEN", away: "NED", home_score: 0, away_score: 2, winner: "NED", stadium: "Al Thumama Stadium", attendance: 41_721 },
  { match_number: 17, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 25), home: "QAT", away: "SEN", home_score: 1, away_score: 3, winner: "SEN", stadium: "Al Thumama Stadium", attendance: 41_797 },
  { match_number: 18, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 25), home: "NED", away: "ECU", home_score: 1, away_score: 1, stadium: "Khalifa International Stadium", attendance: 44_833 },
  { match_number: 33, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 29), home: "ECU", away: "SEN", home_score: 1, away_score: 2, winner: "SEN", stadium: "Khalifa International Stadium", attendance: 44_569 },
  { match_number: 34, stage: :group_stage, group_letter: "A", date: Date.new(2022, 11, 29), home: "NED", away: "QAT", home_score: 2, away_score: 0, winner: "NED", stadium: "Al Bayt Stadium", attendance: 66_784 },

  # Group B: England, Iran, USA, Wales
  { match_number: 3,  stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 21), home: "ENG", away: "IRN", home_score: 6, away_score: 2, winner: "ENG", stadium: "Khalifa International Stadium", attendance: 45_334 },
  { match_number: 4,  stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 21), home: "USA", away: "WAL", home_score: 1, away_score: 1, stadium: "Ahmad bin Ali Stadium", attendance: 43_418 },
  { match_number: 19, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 25), home: "WAL", away: "IRN", home_score: 0, away_score: 2, winner: "IRN", stadium: "Ahmad bin Ali Stadium", attendance: 40_875 },
  { match_number: 20, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 25), home: "ENG", away: "USA", home_score: 0, away_score: 0, stadium: "Al Bayt Stadium", attendance: 68_463 },
  { match_number: 35, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 29), home: "WAL", away: "ENG", home_score: 0, away_score: 3, winner: "ENG", stadium: "Ahmad bin Ali Stadium", attendance: 44_297 },
  { match_number: 36, stage: :group_stage, group_letter: "B", date: Date.new(2022, 11, 29), home: "IRN", away: "USA", home_score: 0, away_score: 1, winner: "USA", stadium: "Al Thumama Stadium", attendance: 42_127 },

  # Group C: Argentina, Saudi Arabia, Mexico, Poland
  { match_number: 7,  stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 22), home: "ARG", away: "KSA", home_score: 1, away_score: 2, winner: "KSA", stadium: "Lusail Iconic Stadium", attendance: 88_012 },
  { match_number: 8,  stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 22), home: "MEX", away: "POL", home_score: 0, away_score: 0, stadium: "Stadium 974", attendance: 39_369 },
  { match_number: 21, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 26), home: "POL", away: "KSA", home_score: 2, away_score: 0, winner: "POL", stadium: "Education City Stadium", attendance: 44_259 },
  { match_number: 22, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 26), home: "ARG", away: "MEX", home_score: 2, away_score: 0, winner: "ARG", stadium: "Lusail Iconic Stadium", attendance: 88_966 },
  { match_number: 37, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 30), home: "POL", away: "ARG", home_score: 0, away_score: 2, winner: "ARG", stadium: "Stadium 974", attendance: 44_322 },
  { match_number: 38, stage: :group_stage, group_letter: "C", date: Date.new(2022, 11, 30), home: "KSA", away: "MEX", home_score: 1, away_score: 2, winner: "MEX", stadium: "Lusail Iconic Stadium", attendance: 84_985 },

  # Group D: France, Australia, Denmark, Tunisia
  { match_number: 5,  stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 22), home: "DEN", away: "TUN", home_score: 0, away_score: 0, stadium: "Education City Stadium", attendance: 42_925 },
  { match_number: 9,  stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 22), home: "FRA", away: "AUS", home_score: 4, away_score: 1, winner: "FRA", stadium: "Al Janoub Stadium", attendance: 40_875 },
  { match_number: 23, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 26), home: "TUN", away: "AUS", home_score: 0, away_score: 1, winner: "AUS", stadium: "Al Janoub Stadium", attendance: 41_823 },
  { match_number: 24, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 26), home: "FRA", away: "DEN", home_score: 2, away_score: 1, winner: "FRA", stadium: "Stadium 974", attendance: 42_860 },
  { match_number: 39, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 30), home: "TUN", away: "FRA", home_score: 1, away_score: 0, winner: "TUN", stadium: "Education City Stadium", attendance: 43_443 },
  { match_number: 40, stage: :group_stage, group_letter: "D", date: Date.new(2022, 11, 30), home: "AUS", away: "DEN", home_score: 1, away_score: 0, winner: "AUS", stadium: "Al Janoub Stadium", attendance: 41_232 },

  # Group E: Spain, Costa Rica, Germany, Japan
  { match_number: 11, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 23), home: "GER", away: "JPN", home_score: 1, away_score: 2, winner: "JPN", stadium: "Khalifa International Stadium", attendance: 42_608 },
  { match_number: 12, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 23), home: "ESP", away: "CRC", home_score: 7, away_score: 0, winner: "ESP", stadium: "Al Thumama Stadium", attendance: 40_013 },
  { match_number: 25, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 27), home: "JPN", away: "CRC", home_score: 0, away_score: 1, winner: "CRC", stadium: "Ahmad bin Ali Stadium", attendance: 41_479 },
  { match_number: 26, stage: :group_stage, group_letter: "E", date: Date.new(2022, 11, 27), home: "ESP", away: "GER", home_score: 1, away_score: 1, stadium: "Al Bayt Stadium", attendance: 68_895 },
  { match_number: 41, stage: :group_stage, group_letter: "E", date: Date.new(2022, 12, 1), home: "JPN", away: "ESP", home_score: 2, away_score: 1, winner: "JPN", stadium: "Khalifa International Stadium", attendance: 44_851 },
  { match_number: 42, stage: :group_stage, group_letter: "E", date: Date.new(2022, 12, 1), home: "CRC", away: "GER", home_score: 2, away_score: 4, winner: "GER", stadium: "Al Bayt Stadium", attendance: 67_054 },

  # Group F: Belgium, Canada, Morocco, Croatia
  { match_number: 10, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 23), home: "MAR", away: "CRO", home_score: 0, away_score: 0, stadium: "Al Bayt Stadium", attendance: 59_407 },
  { match_number: 13, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 23), home: "BEL", away: "CAN", home_score: 1, away_score: 0, winner: "BEL", stadium: "Ahmad bin Ali Stadium", attendance: 40_432 },
  { match_number: 27, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 27), home: "BEL", away: "MAR", home_score: 0, away_score: 2, winner: "MAR", stadium: "Al Thumama Stadium", attendance: 43_738 },
  { match_number: 28, stage: :group_stage, group_letter: "F", date: Date.new(2022, 11, 27), home: "CRO", away: "CAN", home_score: 4, away_score: 1, winner: "CRO", stadium: "Khalifa International Stadium", attendance: 44_374 },
  { match_number: 43, stage: :group_stage, group_letter: "F", date: Date.new(2022, 12, 1), home: "CRO", away: "BEL", home_score: 0, away_score: 0, stadium: "Ahmad bin Ali Stadium", attendance: 43_984 },
  { match_number: 44, stage: :group_stage, group_letter: "F", date: Date.new(2022, 12, 1), home: "CAN", away: "MAR", home_score: 1, away_score: 2, winner: "MAR", stadium: "Al Thumama Stadium", attendance: 43_102 },

  # Group G: Brazil, Serbia, Switzerland, Cameroon
  { match_number: 14, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 24), home: "SUI", away: "CMR", home_score: 1, away_score: 0, winner: "SUI", stadium: "Al Janoub Stadium", attendance: 39_089 },
  { match_number: 15, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 24), home: "BRA", away: "SRB", home_score: 2, away_score: 0, winner: "BRA", stadium: "Lusail Iconic Stadium", attendance: 88_103 },
  { match_number: 29, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 28), home: "CMR", away: "SRB", home_score: 3, away_score: 3, stadium: "Al Janoub Stadium", attendance: 39_789 },
  { match_number: 30, stage: :group_stage, group_letter: "G", date: Date.new(2022, 11, 28), home: "BRA", away: "SUI", home_score: 1, away_score: 0, winner: "BRA", stadium: "Stadium 974", attendance: 43_649 },
  { match_number: 45, stage: :group_stage, group_letter: "G", date: Date.new(2022, 12, 2), home: "SRB", away: "SUI", home_score: 2, away_score: 3, winner: "SUI", stadium: "Stadium 974", attendance: 41_378 },
  { match_number: 46, stage: :group_stage, group_letter: "G", date: Date.new(2022, 12, 2), home: "CMR", away: "BRA", home_score: 1, away_score: 0, winner: "CMR", stadium: "Lusail Iconic Stadium", attendance: 85_986 },

  # Group H: Portugal, Ghana, Uruguay, South Korea
  { match_number: 6,  stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 24), home: "URU", away: "KOR", home_score: 0, away_score: 0, stadium: "Education City Stadium", attendance: 41_663 },
  { match_number: 16, stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 24), home: "POR", away: "GHA", home_score: 3, away_score: 2, winner: "POR", stadium: "Stadium 974", attendance: 42_662 },
  { match_number: 31, stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 28), home: "KOR", away: "GHA", home_score: 2, away_score: 3, winner: "GHA", stadium: "Education City Stadium", attendance: 43_983 },
  { match_number: 32, stage: :group_stage, group_letter: "H", date: Date.new(2022, 11, 28), home: "POR", away: "URU", home_score: 2, away_score: 0, winner: "POR", stadium: "Lusail Iconic Stadium", attendance: 88_668 },
  { match_number: 47, stage: :group_stage, group_letter: "H", date: Date.new(2022, 12, 2), home: "KOR", away: "POR", home_score: 2, away_score: 1, winner: "KOR", stadium: "Education City Stadium", attendance: 44_097 },
  { match_number: 48, stage: :group_stage, group_letter: "H", date: Date.new(2022, 12, 2), home: "GHA", away: "URU", home_score: 0, away_score: 2, winner: "URU", stadium: "Al Janoub Stadium", attendance: 43_443 },

  # Round of 16
  { match_number: 49, stage: :round_of_16, date: Date.new(2022, 12, 3), home: "NED", away: "USA", home_score: 3, away_score: 1, winner: "NED", stadium: "Khalifa International Stadium", attendance: 44_846 },
  { match_number: 50, stage: :round_of_16, date: Date.new(2022, 12, 3), home: "ARG", away: "AUS", home_score: 2, away_score: 1, winner: "ARG", stadium: "Ahmad bin Ali Stadium", attendance: 45_032 },
  { match_number: 51, stage: :round_of_16, date: Date.new(2022, 12, 4), home: "FRA", away: "POL", home_score: 3, away_score: 1, winner: "FRA", stadium: "Al Thumama Stadium", attendance: 40_989 },
  { match_number: 52, stage: :round_of_16, date: Date.new(2022, 12, 4), home: "ENG", away: "SEN", home_score: 3, away_score: 0, winner: "ENG", stadium: "Al Bayt Stadium", attendance: 65_985 },
  { match_number: 53, stage: :round_of_16, date: Date.new(2022, 12, 5), home: "JPN", away: "CRO",
    home_score: 1, away_score: 1, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 1, away_penalties: 3, result_type: :after_penalties, winner: "CRO",
    stadium: "Al Janoub Stadium", attendance: 42_523 },
  { match_number: 54, stage: :round_of_16, date: Date.new(2022, 12, 5), home: "BRA", away: "KOR", home_score: 4, away_score: 1, winner: "BRA", stadium: "Stadium 974", attendance: 43_847 },
  { match_number: 55, stage: :round_of_16, date: Date.new(2022, 12, 6), home: "MAR", away: "ESP",
    home_score: 0, away_score: 0, home_score_after_extra_time: 0, away_score_after_extra_time: 0,
    home_penalties: 3, away_penalties: 0, result_type: :after_penalties, winner: "MAR",
    stadium: "Education City Stadium", attendance: 44_667 },
  { match_number: 56, stage: :round_of_16, date: Date.new(2022, 12, 6), home: "POR", away: "SUI", home_score: 6, away_score: 1, winner: "POR", stadium: "Lusail Iconic Stadium", attendance: 83_720 },

  # Quarter-finals
  { match_number: 57, stage: :quarter_final, date: Date.new(2022, 12, 9), home: "NED", away: "ARG",
    home_score: 2, away_score: 2, home_score_after_extra_time: 2, away_score_after_extra_time: 2,
    home_penalties: 3, away_penalties: 4, result_type: :after_penalties, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_235, data_confidence: :verified },
  { match_number: 58, stage: :quarter_final, date: Date.new(2022, 12, 9), home: "CRO", away: "BRA",
    home_score: 0, away_score: 0, home_score_after_extra_time: 1, away_score_after_extra_time: 1,
    home_penalties: 4, away_penalties: 2, result_type: :after_penalties, winner: "CRO",
    stadium: "Education City Stadium", attendance: 43_893, data_confidence: :verified },
  { match_number: 59, stage: :quarter_final, date: Date.new(2022, 12, 10), home: "MAR", away: "POR", home_score: 1, away_score: 0, winner: "MAR", stadium: "Al Thumama Stadium", attendance: 44_198, data_confidence: :verified },
  { match_number: 60, stage: :quarter_final, date: Date.new(2022, 12, 10), home: "ENG", away: "FRA", home_score: 1, away_score: 2, winner: "FRA", stadium: "Al Bayt Stadium", attendance: 68_895, data_confidence: :verified },

  # Semi-finals
  { match_number: 61, stage: :semi_final, date: Date.new(2022, 12, 13), home: "ARG", away: "CRO", home_score: 3, away_score: 0, winner: "ARG", stadium: "Lusail Iconic Stadium", attendance: 88_966, data_confidence: :verified },
  { match_number: 62, stage: :semi_final, date: Date.new(2022, 12, 14), home: "FRA", away: "MAR", home_score: 2, away_score: 0, winner: "FRA", stadium: "Al Bayt Stadium", attendance: 68_294, data_confidence: :verified },

  # Third-place playoff
  { match_number: 63, stage: :third_place_playoff, date: Date.new(2022, 12, 17), home: "CRO", away: "MAR", home_score: 2, away_score: 1, winner: "CRO", stadium: "Khalifa International Stadium", attendance: 44_137, data_confidence: :verified },

  # Final
  { match_number: 64, stage: :final, date: Date.new(2022, 12, 18), home: "ARG", away: "FRA",
    home_score: 2, away_score: 2, home_score_after_extra_time: 3, away_score_after_extra_time: 3,
    home_penalties: 4, away_penalties: 2, result_type: :after_penalties, winner: "ARG",
    stadium: "Lusail Iconic Stadium", attendance: 88_966, data_confidence: :verified }
].freeze

TOURNAMENT_MATCHES = {
  1986 => MATCHES_1986,
  2018 => MATCHES_2018,
  2022 => MATCHES_2022
}.freeze

TOURNAMENT_MATCHES.each do |year, matches|
  tournament = Tournament.find_by!(year: year)
  matches.each do |attrs|
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
      m.source_notes = attrs[:notes]
    end
  end
end

puts "Matches: #{Match.count} (target: #{TOURNAMENT_MATCHES.values.map(&:size).sum})"
