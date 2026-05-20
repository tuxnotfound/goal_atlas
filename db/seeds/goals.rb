# All 172 goals from the 2022 FIFA World Cup.
#
# Goal-ordering convention:
#   - minute / stoppage_time match the clock at which the goal was credited
#     (e.g. 90+11 for Weghorst's late equaliser is minute: 90, stoppage_time: 11)
#   - period determines first_half / second_half / extra_time_first / extra_time_second
#   - score_after_goal_home / _away are the cumulative match score after the goal
#   - For own goals: player is the scorer, scoring_team is the OPPOSING team
#     that was credited
#
# Depends on: matches.rb, players.rb, teams.rb

tournament = Tournament.find_by!(year: 2022)

def player!(name) = Player.find_by!(name: name)
def t!(code)      = Team.find_by!(fifa_code: code)

def match!(tournament, number) = Match.find_by!(tournament: tournament, match_number: number)

GOALS_2022 = [
  # ============================================================
  # GROUP STAGE
  # ============================================================

  # Match 1: Qatar 0-2 Ecuador
  { match: 1, player: "Enner Valencia", team: "ECU", minute: 16, period: :first_half,  type: :penalty,   score: [0, 1] },
  { match: 1, player: "Enner Valencia", team: "ECU", minute: 31, period: :first_half,  type: :open_play, body: :head, score: [0, 2] },

  # Match 2: Senegal 0-2 Netherlands
  { match: 2, player: "Cody Gakpo",    team: "NED", minute: 84,                period: :second_half, type: :open_play, body: :head,      score: [0, 1] },
  { match: 2, player: "Davy Klaassen", team: "NED", minute: 90, stoppage: 9,   period: :second_half, type: :open_play,                   score: [0, 2] },

  # Match 3: England 6-2 Iran
  { match: 3, player: "Jude Bellingham", team: "ENG", minute: 35, period: :first_half,  type: :open_play, body: :head, score: [1, 0] },
  { match: 3, player: "Bukayo Saka",     team: "ENG", minute: 43, period: :first_half,  type: :open_play,              score: [2, 0] },
  { match: 3, player: "Raheem Sterling", team: "ENG", minute: 45, stoppage: 1, period: :first_half, type: :open_play,  score: [3, 0] },
  { match: 3, player: "Bukayo Saka",     team: "ENG", minute: 62, period: :second_half, type: :open_play,              score: [4, 0] },
  { match: 3, player: "Mehdi Taremi",    team: "IRN", minute: 65, period: :second_half, type: :open_play,              score: [4, 1] },
  { match: 3, player: "Marcus Rashford", team: "ENG", minute: 71, period: :second_half, type: :open_play,              score: [5, 1] },
  { match: 3, player: "Jack Grealish",   team: "ENG", minute: 90, period: :second_half, type: :open_play,              score: [6, 1] },
  { match: 3, player: "Mehdi Taremi",    team: "IRN", minute: 90, stoppage: 13, period: :second_half, type: :penalty,  score: [6, 2] },

  # Match 4: USA 1-1 Wales
  { match: 4, player: "Timothy Weah", team: "USA", minute: 36, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 4, player: "Gareth Bale",  team: "WAL", minute: 82, period: :second_half, type: :penalty,   score: [1, 1] },

  # Match 5: Denmark 0-0 Tunisia — no goals

  # Match 6: Uruguay 0-0 South Korea — no goals

  # Match 7: Argentina 1-2 Saudi Arabia
  { match: 7, player: "Lionel Messi",       team: "ARG", minute: 10, period: :first_half,  type: :penalty,   body: :left_foot, score: [1, 0] },
  { match: 7, player: "Saleh Al-Shehri",    team: "KSA", minute: 48, period: :second_half, type: :open_play,                   score: [1, 1] },
  { match: 7, player: "Salem Al-Dawsari",   team: "KSA", minute: 53, period: :second_half, type: :open_play,                   score: [1, 2] },

  # Match 8: Mexico 0-0 Poland — no goals

  # Match 9: France 4-1 Australia
  { match: 9, player: "Craig Goodwin",    team: "AUS", minute: 9,  period: :first_half,  type: :open_play, score: [0, 1] },
  { match: 9, player: "Adrien Rabiot",    team: "FRA", minute: 27, period: :first_half,  type: :open_play, body: :head, score: [1, 1] },
  { match: 9, player: "Olivier Giroud",   team: "FRA", minute: 32, period: :first_half,  type: :open_play, score: [2, 1] },
  { match: 9, player: "Kylian Mbappé",    team: "FRA", minute: 68, period: :second_half, type: :open_play, body: :head, score: [3, 1] },
  { match: 9, player: "Olivier Giroud",   team: "FRA", minute: 71, period: :second_half, type: :open_play, body: :head, score: [4, 1] },

  # Match 10: Morocco 0-0 Croatia — no goals

  # Match 11: Germany 1-2 Japan
  { match: 11, player: "İlkay Gündoğan", team: "GER", minute: 33, period: :first_half,  type: :penalty,   score: [1, 0] },
  { match: 11, player: "Ritsu Dōan",     team: "JPN", minute: 75, period: :second_half, type: :open_play, score: [1, 1] },
  { match: 11, player: "Takuma Asano",   team: "JPN", minute: 83, period: :second_half, type: :open_play, score: [1, 2] },

  # Match 12: Spain 7-0 Costa Rica
  { match: 12, player: "Dani Olmo",      team: "ESP", minute: 11, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 12, player: "Marco Asensio",  team: "ESP", minute: 21, period: :first_half,  type: :open_play, score: [2, 0] },
  { match: 12, player: "Ferran Torres",  team: "ESP", minute: 31, period: :first_half,  type: :penalty,   score: [3, 0] },
  { match: 12, player: "Ferran Torres",  team: "ESP", minute: 54, period: :second_half, type: :open_play, score: [4, 0] },
  { match: 12, player: "Gavi",           team: "ESP", minute: 74, period: :second_half, type: :open_play, score: [5, 0] },
  { match: 12, player: "Carlos Soler",   team: "ESP", minute: 90, period: :second_half, type: :open_play, score: [6, 0] },
  { match: 12, player: "Álvaro Morata",  team: "ESP", minute: 90, stoppage: 2, period: :second_half, type: :open_play, score: [7, 0] },

  # Match 13: Belgium 1-0 Canada
  { match: 13, player: "Michy Batshuayi", team: "BEL", minute: 44, period: :first_half, type: :open_play, score: [1, 0] },

  # Match 14: Switzerland 1-0 Cameroon
  { match: 14, player: "Breel Embolo", team: "SUI", minute: 48, period: :second_half, type: :open_play, score: [1, 0] },

  # Match 15: Brazil 2-0 Serbia
  { match: 15, player: "Richarlison", team: "BRA", minute: 62, period: :second_half, type: :open_play, score: [1, 0] },
  { match: 15, player: "Richarlison", team: "BRA", minute: 73, period: :second_half, type: :open_play, score: [2, 0] },

  # Match 16: Portugal 3-2 Ghana
  { match: 16, player: "Cristiano Ronaldo", team: "POR", minute: 65, period: :second_half, type: :penalty,   score: [1, 0] },
  { match: 16, player: "André Ayew",        team: "GHA", minute: 73, period: :second_half, type: :open_play, score: [1, 1] },
  { match: 16, player: "João Félix",        team: "POR", minute: 78, period: :second_half, type: :open_play, score: [2, 1] },
  { match: 16, player: "Rafael Leão",       team: "POR", minute: 80, period: :second_half, type: :open_play, score: [3, 1] },
  { match: 16, player: "Osman Bukari",      team: "GHA", minute: 89, period: :second_half, type: :open_play, body: :head, score: [3, 2] },

  # Match 17: Qatar 1-3 Senegal
  { match: 17, player: "Boulaye Dia",        team: "SEN", minute: 41, period: :first_half,  type: :open_play, score: [0, 1] },
  { match: 17, player: "Famara Diédhiou",    team: "SEN", minute: 48, period: :second_half, type: :open_play, body: :head, score: [0, 2] },
  { match: 17, player: "Mohammed Muntari",   team: "QAT", minute: 78, period: :second_half, type: :open_play, body: :head, score: [1, 2] },
  { match: 17, player: "Bamba Dieng",        team: "SEN", minute: 90, stoppage: 4, period: :second_half, type: :open_play, score: [1, 3] },

  # Match 18: Netherlands 1-1 Ecuador
  { match: 18, player: "Cody Gakpo",      team: "NED", minute: 6,  period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 18, player: "Enner Valencia",  team: "ECU", minute: 49, period: :second_half, type: :open_play, score: [1, 1] },

  # Match 19: Wales 0-2 Iran
  { match: 19, player: "Rouzbeh Cheshmi", team: "IRN", minute: 90, stoppage: 8,  period: :second_half, type: :open_play, score: [0, 1] },
  { match: 19, player: "Ramin Rezaeian",  team: "IRN", minute: 90, stoppage: 11, period: :second_half, type: :open_play, score: [0, 2] },

  # Match 20: England 0-0 USA — no goals

  # Match 21: Poland 2-0 Saudi Arabia
  { match: 21, player: "Piotr Zieliński",     team: "POL", minute: 39, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 21, player: "Robert Lewandowski",  team: "POL", minute: 82, period: :second_half, type: :open_play, score: [2, 0] },

  # Match 22: Argentina 2-0 Mexico
  { match: 22, player: "Lionel Messi",   team: "ARG", minute: 64, period: :second_half, type: :open_play, score: [1, 0] },
  { match: 22, player: "Enzo Fernández", team: "ARG", minute: 87, period: :second_half, type: :open_play, score: [2, 0] },

  # Match 23: Tunisia 0-1 Australia
  { match: 23, player: "Mitchell Duke", team: "AUS", minute: 23, period: :first_half, type: :open_play, body: :head, score: [0, 1] },

  # Match 24: France 2-1 Denmark
  { match: 24, player: "Kylian Mbappé",        team: "FRA", minute: 61, period: :second_half, type: :open_play, score: [1, 0] },
  { match: 24, player: "Andreas Christensen",  team: "DEN", minute: 68, period: :second_half, type: :open_play, body: :head, score: [1, 1] },
  { match: 24, player: "Kylian Mbappé",        team: "FRA", minute: 86, period: :second_half, type: :open_play, score: [2, 1] },

  # Match 25: Japan 0-1 Costa Rica
  { match: 25, player: "Keysher Fuller", team: "CRC", minute: 81, period: :second_half, type: :open_play, score: [0, 1] },

  # Match 26: Spain 1-1 Germany
  { match: 26, player: "Álvaro Morata",   team: "ESP", minute: 62, period: :second_half, type: :open_play, score: [1, 0] },
  { match: 26, player: "Niclas Füllkrug", team: "GER", minute: 83, period: :second_half, type: :open_play, score: [1, 1] },

  # Match 27: Belgium 0-2 Morocco
  { match: 27, player: "Abdelhamid Sabiri",  team: "MAR", minute: 73, period: :second_half, type: :free_kick, score: [0, 1] },
  { match: 27, player: "Zakaria Aboukhlal",  team: "MAR", minute: 90, stoppage: 2, period: :second_half, type: :open_play, score: [0, 2] },

  # Match 28: Croatia 4-1 Canada
  { match: 28, player: "Alphonso Davies",  team: "CAN", minute: 2,  period: :first_half,  type: :open_play, body: :head, score: [0, 1] },
  { match: 28, player: "Andrej Kramarić",  team: "CRO", minute: 36, period: :first_half,  type: :open_play, score: [1, 1] },
  { match: 28, player: "Marko Livaja",     team: "CRO", minute: 44, period: :first_half,  type: :open_play, score: [2, 1] },
  { match: 28, player: "Andrej Kramarić",  team: "CRO", minute: 70, period: :second_half, type: :open_play, score: [3, 1] },
  { match: 28, player: "Lovro Majer",      team: "CRO", minute: 90, stoppage: 4, period: :second_half, type: :open_play, score: [4, 1] },

  # Match 29: Cameroon 3-3 Serbia
  { match: 29, player: "Jean-Charles Castelletto", team: "CMR", minute: 29, period: :first_half,  type: :open_play, body: :head, score: [1, 0] },
  { match: 29, player: "Strahinja Pavlović",        team: "SRB", minute: 45, stoppage: 1, period: :first_half, type: :open_play, body: :head, score: [1, 1] },
  { match: 29, player: "Sergej Milinković-Savić",  team: "SRB", minute: 45, stoppage: 3, period: :first_half, type: :open_play, score: [1, 2] },
  { match: 29, player: "Aleksandar Mitrović",       team: "SRB", minute: 53, period: :second_half, type: :open_play, score: [1, 3] },
  { match: 29, player: "Vincent Aboubakar",         team: "CMR", minute: 63, period: :second_half, type: :open_play, score: [2, 3] },
  { match: 29, player: "Eric Maxim Choupo-Moting",  team: "CMR", minute: 66, period: :second_half, type: :open_play, score: [3, 3] },

  # Match 30: Brazil 1-0 Switzerland
  { match: 30, player: "Casemiro", team: "BRA", minute: 83, period: :second_half, type: :open_play, score: [1, 0] },

  # Match 31: South Korea 2-3 Ghana
  { match: 31, player: "Mohammed Salisu", team: "GHA", minute: 24, period: :first_half,  type: :open_play, score: [0, 1] },
  { match: 31, player: "Mohammed Kudus",  team: "GHA", minute: 34, period: :first_half,  type: :open_play, body: :head, score: [0, 2] },
  { match: 31, player: "Cho Gue-sung",    team: "KOR", minute: 58, period: :second_half, type: :open_play, body: :head, score: [1, 2] },
  { match: 31, player: "Cho Gue-sung",    team: "KOR", minute: 61, period: :second_half, type: :open_play, body: :head, score: [2, 2] },
  { match: 31, player: "Mohammed Kudus",  team: "GHA", minute: 68, period: :second_half, type: :open_play, score: [2, 3] },

  # Match 32: Portugal 2-0 Uruguay
  { match: 32, player: "Bruno Fernandes", team: "POR", minute: 54, period: :second_half, type: :open_play, score: [1, 0] },
  { match: 32, player: "Bruno Fernandes", team: "POR", minute: 90, stoppage: 3, period: :second_half, type: :penalty,   score: [2, 0] },

  # Match 33: Ecuador 1-2 Senegal
  { match: 33, player: "Ismaïla Sarr",      team: "SEN", minute: 44, period: :first_half,  type: :penalty,   score: [0, 1] },
  { match: 33, player: "Moisés Caicedo",    team: "ECU", minute: 67, period: :second_half, type: :open_play, score: [1, 1] },
  { match: 33, player: "Kalidou Koulibaly", team: "SEN", minute: 70, period: :second_half, type: :open_play, score: [1, 2] },

  # Match 34: Netherlands 2-0 Qatar
  { match: 34, player: "Cody Gakpo",      team: "NED", minute: 26, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 34, player: "Frenkie de Jong", team: "NED", minute: 49, period: :second_half, type: :open_play, score: [2, 0] },

  # Match 35: Wales 0-3 England
  { match: 35, player: "Marcus Rashford", team: "ENG", minute: 50, period: :second_half, type: :free_kick, score: [0, 1] },
  { match: 35, player: "Phil Foden",      team: "ENG", minute: 51, period: :second_half, type: :open_play, score: [0, 2] },
  { match: 35, player: "Marcus Rashford", team: "ENG", minute: 68, period: :second_half, type: :open_play, score: [0, 3] },

  # Match 36: Iran 0-1 USA
  { match: 36, player: "Christian Pulisic", team: "USA", minute: 38, period: :first_half, type: :open_play, score: [0, 1] },

  # Match 37: Poland 0-2 Argentina
  { match: 37, player: "Alexis Mac Allister", team: "ARG", minute: 46, period: :second_half, type: :open_play, score: [0, 1] },
  { match: 37, player: "Julián Álvarez",      team: "ARG", minute: 67, period: :second_half, type: :open_play, score: [0, 2] },

  # Match 38: Saudi Arabia 1-2 Mexico
  { match: 38, player: "Henry Martín",     team: "MEX", minute: 47, period: :second_half, type: :open_play, score: [0, 1] },
  { match: 38, player: "Luis Chávez",      team: "MEX", minute: 52, period: :second_half, type: :free_kick, score: [0, 2] },
  { match: 38, player: "Salem Al-Dawsari", team: "KSA", minute: 90, stoppage: 5, period: :second_half, type: :open_play, score: [1, 2] },

  # Match 39: Tunisia 1-0 France
  { match: 39, player: "Wahbi Khazri", team: "TUN", minute: 58, period: :second_half, type: :open_play, score: [1, 0] },

  # Match 40: Australia 1-0 Denmark
  { match: 40, player: "Mathew Leckie", team: "AUS", minute: 60, period: :second_half, type: :open_play, score: [1, 0] },

  # Match 41: Japan 2-1 Spain
  { match: 41, player: "Álvaro Morata", team: "ESP", minute: 11, period: :first_half,  type: :open_play, body: :head, score: [0, 1] },
  { match: 41, player: "Ritsu Dōan",    team: "JPN", minute: 48, period: :second_half, type: :open_play, score: [1, 1] },
  { match: 41, player: "Ao Tanaka",     team: "JPN", minute: 51, period: :second_half, type: :open_play, score: [2, 1] },

  # Match 42: Costa Rica 2-4 Germany
  { match: 42, player: "Serge Gnabry",       team: "GER", minute: 10, period: :first_half,  type: :open_play, body: :head, score: [0, 1] },
  { match: 42, player: "Yeltsin Tejeda",     team: "CRC", minute: 58, period: :second_half, type: :open_play, score: [1, 1] },
  { match: 42, player: "Juan Pablo Vargas",  team: "CRC", minute: 70, period: :second_half, type: :open_play, score: [2, 1] },
  { match: 42, player: "Kai Havertz",        team: "GER", minute: 73, period: :second_half, type: :open_play, score: [2, 2] },
  { match: 42, player: "Kai Havertz",        team: "GER", minute: 85, period: :second_half, type: :open_play, score: [2, 3] },
  { match: 42, player: "Niclas Füllkrug",    team: "GER", minute: 89, period: :second_half, type: :open_play, score: [2, 4] },

  # Match 43: Croatia 0-0 Belgium — no goals

  # Match 44: Canada 1-2 Morocco
  { match: 44, player: "Hakim Ziyech",      team: "MAR", minute: 4,  period: :first_half, type: :open_play, score: [0, 1] },
  { match: 44, player: "Youssef En-Nesyri", team: "MAR", minute: 23, period: :first_half, type: :open_play, score: [0, 2] },
  { match: 44, player: "Nayef Aguerd",      team: "CAN", minute: 40, period: :first_half, type: :own_goal, score: [1, 2] },

  # Match 45: Serbia 2-3 Switzerland
  { match: 45, player: "Xherdan Shaqiri",     team: "SUI", minute: 20, period: :first_half, type: :open_play, score: [0, 1] },
  { match: 45, player: "Aleksandar Mitrović", team: "SRB", minute: 26, period: :first_half, type: :open_play, body: :head, score: [1, 1] },
  { match: 45, player: "Dušan Vlahović",      team: "SRB", minute: 35, period: :first_half, type: :open_play, score: [2, 1] },
  { match: 45, player: "Breel Embolo",        team: "SUI", minute: 44, period: :first_half, type: :open_play, score: [2, 2] },
  { match: 45, player: "Remo Freuler",        team: "SUI", minute: 48, period: :second_half, type: :open_play, score: [2, 3] },

  # Match 46: Cameroon 1-0 Brazil
  { match: 46, player: "Vincent Aboubakar", team: "CMR", minute: 90, stoppage: 2, period: :second_half, type: :open_play, body: :head, score: [1, 0] },

  # Match 47: South Korea 2-1 Portugal
  { match: 47, player: "Ricardo Horta",   team: "POR", minute: 5,  period: :first_half,  type: :open_play, score: [0, 1] },
  { match: 47, player: "Kim Young-gwon",  team: "KOR", minute: 27, period: :first_half,  type: :open_play, score: [1, 1] },
  { match: 47, player: "Hwang Hee-chan",  team: "KOR", minute: 90, stoppage: 1, period: :second_half, type: :open_play, score: [2, 1] },

  # Match 48: Ghana 0-2 Uruguay
  { match: 48, player: "Giorgian de Arrascaeta", team: "URU", minute: 26, period: :first_half, type: :open_play, body: :head, score: [0, 1] },
  { match: 48, player: "Giorgian de Arrascaeta", team: "URU", minute: 32, period: :first_half, type: :open_play, score: [0, 2] },

  # ============================================================
  # ROUND OF 16
  # ============================================================

  # Match 49: Netherlands 3-1 USA
  { match: 49, player: "Memphis Depay",   team: "NED", minute: 10, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 49, player: "Daley Blind",     team: "NED", minute: 45, stoppage: 1, period: :first_half, type: :open_play, score: [2, 0] },
  { match: 49, player: "Haji Wright",     team: "USA", minute: 76, period: :second_half, type: :open_play, score: [2, 1] },
  { match: 49, player: "Denzel Dumfries", team: "NED", minute: 81, period: :second_half, type: :open_play, score: [3, 1] },

  # Match 50: Argentina 2-1 Australia
  { match: 50, player: "Lionel Messi",   team: "ARG", minute: 35, period: :first_half,  type: :open_play, body: :left_foot, score: [1, 0] },
  { match: 50, player: "Julián Álvarez", team: "ARG", minute: 57, period: :second_half, type: :open_play, score: [2, 0] },
  { match: 50, player: "Enzo Fernández", team: "AUS", minute: 77, period: :second_half, type: :own_goal,  score: [2, 1] },

  # Match 51: France 3-1 Poland
  { match: 51, player: "Olivier Giroud",      team: "FRA", minute: 44, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 51, player: "Kylian Mbappé",       team: "FRA", minute: 74, period: :second_half, type: :open_play, score: [2, 0] },
  { match: 51, player: "Kylian Mbappé",       team: "FRA", minute: 90, stoppage: 1, period: :second_half, type: :open_play, score: [3, 0] },
  { match: 51, player: "Robert Lewandowski",  team: "POL", minute: 90, stoppage: 9, period: :second_half, type: :penalty,   score: [3, 1] },

  # Match 52: England 3-0 Senegal
  { match: 52, player: "Jordan Henderson", team: "ENG", minute: 38, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 52, player: "Harry Kane",       team: "ENG", minute: 45, stoppage: 3, period: :first_half, type: :open_play, score: [2, 0] },
  { match: 52, player: "Bukayo Saka",      team: "ENG", minute: 57, period: :second_half, type: :open_play, score: [3, 0] },

  # Match 53: Japan 1-1 Croatia (Croatia win 3-1 pens)
  { match: 53, player: "Daizen Maeda",   team: "JPN", minute: 43, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 53, player: "Ivan Perišić",   team: "CRO", minute: 55, period: :second_half, type: :open_play, body: :head, score: [1, 1] },

  # Match 54: Brazil 4-1 South Korea
  { match: 54, player: "Vinícius Júnior", team: "BRA", minute: 7,  period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 54, player: "Neymar",          team: "BRA", minute: 13, period: :first_half,  type: :penalty,   score: [2, 0] },
  { match: 54, player: "Richarlison",     team: "BRA", minute: 29, period: :first_half,  type: :open_play, score: [3, 0] },
  { match: 54, player: "Lucas Paquetá",   team: "BRA", minute: 36, period: :first_half,  type: :open_play, score: [4, 0] },
  { match: 54, player: "Paik Seung-ho",   team: "KOR", minute: 76, period: :second_half, type: :open_play, score: [4, 1] },

  # Match 55: Morocco 0-0 Spain (Morocco win 3-0 pens) — no goals in regulation/ET

  # Match 56: Portugal 6-1 Switzerland
  { match: 56, player: "Gonçalo Ramos",       team: "POR", minute: 17, period: :first_half,  type: :open_play, score: [1, 0] },
  { match: 56, player: "Pepe",                team: "POR", minute: 33, period: :first_half,  type: :open_play, body: :head, score: [2, 0] },
  { match: 56, player: "Gonçalo Ramos",       team: "POR", minute: 51, period: :second_half, type: :open_play, score: [3, 0] },
  { match: 56, player: "Raphaël Guerreiro",   team: "POR", minute: 55, period: :second_half, type: :open_play, score: [4, 0] },
  { match: 56, player: "Manuel Akanji",       team: "SUI", minute: 58, period: :second_half, type: :open_play, body: :head, score: [4, 1] },
  { match: 56, player: "Gonçalo Ramos",       team: "POR", minute: 67, period: :second_half, type: :open_play, score: [5, 1] },
  { match: 56, player: "Rafael Leão",         team: "POR", minute: 90, stoppage: 3, period: :second_half, type: :open_play, score: [6, 1] },

  # ============================================================
  # QUARTER-FINALS
  # ============================================================

  # Match 57: Netherlands 2-2 Argentina (Argentina win 4-3 on pens)
  { match: 57, player: "Nahuel Molina",   team: "ARG", minute: 35, period: :first_half,  type: :open_play, score: [0, 1] },
  { match: 57, player: "Lionel Messi",    team: "ARG", minute: 73, period: :second_half, type: :penalty,    body: :left_foot, score: [0, 2] },
  { match: 57, player: "Wout Weghorst",   team: "NED", minute: 83, period: :second_half, type: :open_play,  score: [1, 2] },
  { match: 57, player: "Wout Weghorst",   team: "NED", minute: 90, stoppage: 11, period: :second_half, type: :free_kick, score: [2, 2] },

  # Match 58: Croatia 1-1 Brazil (Croatia win 4-2 on pens)
  { match: 58, player: "Neymar",          team: "BRA", minute: 105, stoppage: 1, period: :extra_time_first,  type: :open_play, score: [0, 1] },
  { match: 58, player: "Bruno Petković",  team: "CRO", minute: 117, stoppage: 3, period: :extra_time_second, type: :open_play, score: [1, 1] },

  # Match 59: Morocco 1-0 Portugal
  { match: 59, player: "Youssef En-Nesyri", team: "MAR", minute: 42, period: :first_half, type: :open_play, body: :head, score: [1, 0] },

  # Match 60: England 1-2 France
  { match: 60, player: "Aurélien Tchouaméni", team: "FRA", minute: 17, period: :first_half,  type: :open_play, body: :right_foot, score: [0, 1] },
  { match: 60, player: "Harry Kane",          team: "ENG", minute: 54, period: :second_half, type: :penalty,   body: :right_foot, score: [1, 1] },
  { match: 60, player: "Olivier Giroud",      team: "FRA", minute: 78, period: :second_half, type: :open_play, body: :head,       score: [1, 2] },

  # ============================================================
  # SEMI-FINALS
  # ============================================================

  # Match 61: Argentina 3-0 Croatia
  { match: 61, player: "Lionel Messi",   team: "ARG", minute: 34, period: :first_half,  type: :penalty,   body: :left_foot, score: [1, 0] },
  { match: 61, player: "Julián Álvarez", team: "ARG", minute: 39, period: :first_half,  type: :open_play, score: [2, 0] },
  { match: 61, player: "Julián Álvarez", team: "ARG", minute: 69, period: :second_half, type: :open_play, score: [3, 0] },

  # Match 62: France 2-0 Morocco
  { match: 62, player: "Theo Hernández",    team: "FRA", minute: 5,  period: :first_half,  type: :open_play, body: :left_foot, score: [1, 0] },
  { match: 62, player: "Randal Kolo Muani", team: "FRA", minute: 79, period: :second_half, type: :open_play, score: [2, 0] },

  # ============================================================
  # THIRD-PLACE PLAYOFF
  # ============================================================

  # Match 63: Croatia 2-1 Morocco
  { match: 63, player: "Joško Gvardiol",  team: "CRO", minute: 7,  period: :first_half, type: :open_play, body: :head,      score: [1, 0] },
  { match: 63, player: "Achraf Dari",     team: "MAR", minute: 9,  period: :first_half, type: :open_play, body: :head,      score: [1, 1] },
  { match: 63, player: "Mislav Oršić",    team: "CRO", minute: 42, period: :first_half, type: :open_play, body: :left_foot, score: [2, 1] },

  # ============================================================
  # FINAL
  # ============================================================

  # Match 64: Argentina 3-3 France (Argentina win 4-2 on pens)
  { match: 64, player: "Lionel Messi",   team: "ARG", minute: 23,  period: :first_half,        type: :penalty,   body: :left_foot,  score: [1, 0] },
  { match: 64, player: "Ángel Di María", team: "ARG", minute: 36,  period: :first_half,        type: :open_play, body: :left_foot,  score: [2, 0] },
  { match: 64, player: "Kylian Mbappé",  team: "FRA", minute: 80,  period: :second_half,       type: :penalty,   body: :right_foot, score: [2, 1] },
  { match: 64, player: "Kylian Mbappé",  team: "FRA", minute: 81,  period: :second_half,       type: :open_play, body: :right_foot, score: [2, 2] },
  { match: 64, player: "Lionel Messi",   team: "ARG", minute: 108, period: :extra_time_first,  type: :open_play, body: :right_foot, score: [3, 2] },
  { match: 64, player: "Kylian Mbappé",  team: "FRA", minute: 118, period: :extra_time_second, type: :penalty,   body: :right_foot, score: [3, 3] }
].freeze

# ============================================================
# 1986 — iconic goals only (finals + Hand of God + Goal of the Century)
# ============================================================
GOALS_1986 = [
  # Match 47: Argentina 2-1 England (QF, Hand of God + Goal of the Century)
  { match: 47, player: "Diego Maradona", team: "ARG", minute: 51, period: :second_half, type: :open_play,
    body: :other,
    score: [1, 0], notes: "Hand of God" },
  { match: 47, player: "Diego Maradona", team: "ARG", minute: 55, period: :second_half, type: :open_play,
    body: :left_foot,
    score: [2, 0], notes: "Goal of the Century — solo run from his own half" },
  { match: 47, player: "Gary Lineker",   team: "ENG", minute: 80, period: :second_half, type: :open_play,
    body: :head,
    score: [2, 1] },

  # Match 52: Argentina 3-2 West Germany (FINAL)
  { match: 52, player: "José Luis Brown",       team: "ARG", minute: 23, period: :first_half,  type: :open_play, body: :head,       score: [1, 0] },
  { match: 52, player: "Jorge Valdano",         team: "ARG", minute: 56, period: :second_half, type: :open_play, body: :left_foot,  score: [2, 0] },
  { match: 52, player: "Karl-Heinz Rummenigge", team: "FRG", minute: 74, period: :second_half, type: :open_play,                    score: [2, 1] },
  { match: 52, player: "Rudi Völler",           team: "FRG", minute: 80, period: :second_half, type: :open_play, body: :head,       score: [2, 2] },
  { match: 52, player: "Jorge Burruchaga",      team: "ARG", minute: 84, period: :second_half, type: :open_play,                    score: [3, 2] }
].freeze

# ============================================================
# 2018 — iconic goals only (final + Pavard's vs Argentina)
# ============================================================
GOALS_2018 = [
  # Match 49: France 4-3 Argentina (R16, Pavard wonder goal)
  { match: 49, player: "Antoine Griezmann", team: "FRA", minute: 13, period: :first_half,  type: :penalty,   score: [1, 0] },
  { match: 49, player: "Ángel Di María",    team: "ARG", minute: 41, period: :first_half,  type: :open_play, score: [1, 1] },
  { match: 49, player: "Gabriel Mercado",   team: "ARG", minute: 48, period: :second_half, type: :open_play, score: [1, 2] }, # Mercado not in seed
  { match: 49, player: "Benjamin Pavard",   team: "FRA", minute: 57, period: :second_half, type: :open_play, body: :right_foot, score: [2, 2], notes: "Wonder goal — curling volley" },
  { match: 49, player: "Kylian Mbappé",     team: "FRA", minute: 64, period: :second_half, type: :open_play, score: [3, 2] },
  { match: 49, player: "Kylian Mbappé",     team: "FRA", minute: 68, period: :second_half, type: :open_play, score: [4, 2] },
  { match: 49, player: "Sergio Agüero",     team: "ARG", minute: 90, stoppage: 3, period: :second_half, type: :open_play, score: [4, 3] }, # Agüero not in seed

  # Match 64: France 4-2 Croatia (FINAL)
  { match: 64, player: "Mario Mandžukić",   team: "FRA", minute: 18, period: :first_half,  type: :own_goal, score: [1, 0] },
  { match: 64, player: "Ivan Perišić",      team: "CRO", minute: 28, period: :first_half,  type: :open_play, score: [1, 1] },
  { match: 64, player: "Antoine Griezmann", team: "FRA", minute: 38, period: :first_half,  type: :penalty,   score: [2, 1] },
  { match: 64, player: "Paul Pogba",        team: "FRA", minute: 59, period: :second_half, type: :open_play, score: [3, 1] },
  { match: 64, player: "Kylian Mbappé",     team: "FRA", minute: 65, period: :second_half, type: :open_play, score: [4, 1] },
  { match: 64, player: "Mario Mandžukić",   team: "CRO", minute: 69, period: :second_half, type: :open_play, score: [4, 2] }
].freeze

TOURNAMENT_GOALS = {
  1986 => GOALS_1986,
  2018 => GOALS_2018,
  2022 => GOALS_2022
}.freeze

TOURNAMENT_GOALS.each do |year, goals_data|
  t_obj = Tournament.find_by!(year: year)
  goals_data.each do |attrs|
    next unless Player.exists?(name: attrs[:player]) # skip if player not seeded

    m = Match.find_by!(tournament: t_obj, match_number: attrs[:match])
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
      data_confidence: :likely,
      goal_order: 0,
      description: attrs[:notes]
    )
    goal.save!
  end
end

puts "Goals: #{Goal.count}"
