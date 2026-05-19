# Marquee players from the 2022 World Cup knockout stage.
# Mainly scorers from the QF, SF, 3rd-place, and final matches, plus a few notable
# non-scoring captains/figures for browsing. Birth dates are included only where
# they are well-documented; nil for the rest (better empty than wrong).
#
# Depends on: teams.rb

def find_team!(fifa_code)
  Team.find_by!(fifa_code: fifa_code)
end

PLAYERS_2022 = [
  # Argentina — squad core
  { name: "Lionel Messi",       team: "ARG", position: :forward,    birth_date: Date.new(1987, 6, 24) },
  { name: "Julián Álvarez",     team: "ARG", position: :forward,    birth_date: Date.new(2000, 1, 31) },
  { name: "Ángel Di María",     team: "ARG", position: :forward,    birth_date: Date.new(1988, 2, 14) },
  { name: "Nahuel Molina",      team: "ARG", position: :defender },
  { name: "Gonzalo Montiel",    team: "ARG", position: :defender },
  { name: "Leandro Paredes",    team: "ARG", position: :midfielder },
  { name: "Paulo Dybala",       team: "ARG", position: :forward },
  { name: "Emiliano Martínez",  team: "ARG", position: :goalkeeper },

  # France — squad core
  { name: "Kylian Mbappé",        team: "FRA", position: :forward,    birth_date: Date.new(1998, 12, 20) },
  { name: "Olivier Giroud",       team: "FRA", position: :forward },
  { name: "Aurélien Tchouaméni",  team: "FRA", position: :midfielder },
  { name: "Theo Hernández",       team: "FRA", position: :defender },
  { name: "Randal Kolo Muani",    team: "FRA", position: :forward },
  { name: "Kingsley Coman",       team: "FRA", position: :forward },
  { name: "Hugo Lloris",          team: "FRA", position: :goalkeeper },

  # Croatia
  { name: "Luka Modrić",      team: "CRO", position: :midfielder, birth_date: Date.new(1985, 9, 9) },
  { name: "Bruno Petković",   team: "CRO", position: :forward },
  { name: "Joško Gvardiol",   team: "CRO", position: :defender },
  { name: "Mislav Oršić",     team: "CRO", position: :forward },

  # Morocco
  { name: "Youssef En-Nesyri", team: "MAR", position: :forward },
  { name: "Achraf Dari",       team: "MAR", position: :defender },
  { name: "Hakim Ziyech",      team: "MAR", position: :midfielder },

  # Netherlands
  { name: "Wout Weghorst", team: "NED", position: :forward },

  # Brazil
  { name: "Neymar", team: "BRA", position: :forward, birth_date: Date.new(1992, 2, 5) },

  # England
  { name: "Harry Kane", team: "ENG", position: :forward, birth_date: Date.new(1993, 7, 28) },

  # Portugal
  { name: "Cristiano Ronaldo", team: "POR", position: :forward, birth_date: Date.new(1985, 2, 5) }
].freeze

PLAYERS_2022.each do |attrs|
  team = find_team!(attrs[:team])
  Player.find_or_create_by!(name: attrs[:name]) do |player|
    player.nationality_team = team
    player.position         = attrs[:position]
    player.birth_date       = attrs[:birth_date]
  end
end

puts "Players: #{Player.count} (target: #{PLAYERS_2022.size})"
