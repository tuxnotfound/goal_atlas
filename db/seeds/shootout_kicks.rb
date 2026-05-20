# Penalty shootouts across all seeded tournaments.
#
# Depends on: matches.rb, players.rb, teams.rb

def player!(name) = Player.find_by!(name: name)
def t!(code)      = Team.find_by!(fifa_code: code)

# ============================================================
# 2022 — three shootouts
# ============================================================

# Match 53: Japan vs Croatia (Croatia won 3-1)
JPN_CRO_SHOOTOUT = [
  { order: 1, team: "JPN", player: "Takumi Minamino",   scored: false, notes: "saved by Dominik Livaković" },
  { order: 2, team: "CRO", player: "Nikola Vlašić",     scored: true,  notes: nil },
  { order: 3, team: "JPN", player: "Kaoru Mitoma",      scored: false, notes: "saved by Livaković" },
  { order: 4, team: "CRO", player: "Marcelo Brozović",  scored: true,  notes: nil },
  { order: 5, team: "JPN", player: "Takuma Asano",      scored: true,  notes: nil },
  { order: 6, team: "CRO", player: "Marko Livaja",      scored: false, notes: "hit the post" },
  { order: 7, team: "JPN", player: "Maya Yoshida",      scored: false, notes: "saved by Livaković" },
  { order: 8, team: "CRO", player: "Mario Pašalić",     scored: true,  notes: "won the shootout for Croatia" }
].freeze

# Match 55: Morocco vs Spain (Morocco won 3-0)
MAR_ESP_SHOOTOUT = [
  { order: 1, team: "ESP", player: "Pablo Sarabia",      scored: false, notes: "hit the post" },
  { order: 2, team: "MAR", player: "Abdelhamid Sabiri",  scored: true,  notes: nil },
  { order: 3, team: "ESP", player: "Carlos Soler",       scored: false, notes: "saved by Bono" },
  { order: 4, team: "MAR", player: "Hakim Ziyech",       scored: true,  notes: nil },
  { order: 5, team: "ESP", player: "Sergio Busquets",    scored: false, notes: "saved by Bono" },
  { order: 6, team: "MAR", player: "Achraf Hakimi",      scored: true,  notes: "panenka — won the shootout for Morocco" }
].freeze

# Match 64: Argentina vs France final (Argentina won 4-2)
FINAL_SHOOTOUT_2022 = [
  { order: 1, team: "FRA", player: "Kylian Mbappé",       scored: true,  notes: nil },
  { order: 2, team: "ARG", player: "Lionel Messi",        scored: true,  notes: nil },
  { order: 3, team: "FRA", player: "Kingsley Coman",      scored: false, notes: "saved by Emiliano Martínez" },
  { order: 4, team: "ARG", player: "Paulo Dybala",        scored: true,  notes: nil },
  { order: 5, team: "FRA", player: "Aurélien Tchouaméni", scored: false, notes: "missed wide of the post" },
  { order: 6, team: "ARG", player: "Leandro Paredes",     scored: true,  notes: nil },
  { order: 7, team: "FRA", player: "Randal Kolo Muani",   scored: true,  notes: nil },
  { order: 8, team: "ARG", player: "Gonzalo Montiel",     scored: true,  notes: "won the World Cup for Argentina" }
].freeze

SHOOTOUTS_2022 = {
  53 => JPN_CRO_SHOOTOUT,
  55 => MAR_ESP_SHOOTOUT,
  64 => FINAL_SHOOTOUT_2022
}.freeze

# ============================================================
# 1986 — three QF shootouts
# ============================================================

# Match 45: Brazil 1-1 France (France won 4-3)
BRA_FRA_1986_SHOOTOUT = [
  { order: 1, team: "BRA", player: "Sócrates",          scored: false, notes: "saved by Bats" },
  { order: 2, team: "FRA", player: "Alain Giresse",     scored: true,  notes: nil },
  { order: 3, team: "BRA", player: "Júnior",            scored: true,  notes: nil },
  { order: 4, team: "FRA", player: "Manuel Amoros",     scored: true,  notes: nil },
  { order: 5, team: "BRA", player: "Zico",              scored: true,  notes: nil },
  { order: 6, team: "FRA", player: "Bruno Bellone",     scored: true,  notes: nil },
  { order: 7, team: "BRA", player: "Júlio César",       scored: false, notes: "hit the post" },
  { order: 8, team: "FRA", player: "Michel Platini",    scored: false, notes: "shot over the bar" },
  { order: 9, team: "BRA", player: "Edinho",            scored: true,  notes: nil },
  { order: 10, team: "FRA", player: "Luis Fernández",   scored: true,  notes: "won the shootout for France" }
].freeze

# Match 46: West Germany 0-0 Mexico (West Germany won 4-1)
FRG_MEX_1986_SHOOTOUT = [
  { order: 1, team: "FRG", player: "Klaus Allofs",      scored: true,  notes: nil },
  { order: 2, team: "MEX", player: "Fernando Quirarte", scored: false, notes: "saved by Schumacher" },
  { order: 3, team: "FRG", player: "Andreas Brehme",    scored: true,  notes: nil },
  { order: 4, team: "MEX", player: "Manuel Negrete",    scored: true,  notes: nil },
  { order: 5, team: "FRG", player: "Lothar Matthäus",   scored: true,  notes: nil },
  { order: 6, team: "MEX", player: "Raúl Servin",       scored: false, notes: "shot over the bar" },
  { order: 7, team: "FRG", player: "Pierre Littbarski", scored: true,  notes: "won the shootout for West Germany" }
].freeze

# Match 48: Spain 1-1 Belgium (Belgium won 5-4)
ESP_BEL_1986_SHOOTOUT = [
  { order: 1, team: "ESP", player: "Andoni Goikoetxea", scored: true,  notes: nil },
  { order: 2, team: "BEL", player: "Stéphane Demol",    scored: true,  notes: nil },
  { order: 3, team: "ESP", player: "Manuel Caldéré",    scored: true,  notes: nil },
  { order: 4, team: "BEL", player: "Jan Ceulemans",     scored: true,  notes: nil },
  { order: 5, team: "ESP", player: "Eloy Olaya",        scored: false, notes: "saved by Pfaff" },
  { order: 6, team: "BEL", player: "Enzo Scifo",        scored: true,  notes: nil },
  { order: 7, team: "ESP", player: "Antonio Maceda",    scored: true,  notes: nil },
  { order: 8, team: "BEL", player: "Frank Vercauteren", scored: true,  notes: nil },
  { order: 9, team: "ESP", player: "Julio Salinas",     scored: true,  notes: nil },
  { order: 10, team: "BEL", player: "Leo Van der Elst", scored: true,  notes: "won the shootout for Belgium" }
].freeze

SHOOTOUTS_1986 = {
  45 => BRA_FRA_1986_SHOOTOUT,
  46 => FRG_MEX_1986_SHOOTOUT,
  48 => ESP_BEL_1986_SHOOTOUT
}.freeze

# ============================================================
# 2018 — four knockout shootouts
# ============================================================

# Match 51: Spain 1-1 Russia (Russia won 4-3)
ESP_RUS_2018_SHOOTOUT = [
  { order: 1, team: "RUS", player: "Fyodor Smolov",     scored: true,  notes: nil },
  { order: 2, team: "ESP", player: "Andrés Iniesta",    scored: true,  notes: nil },
  { order: 3, team: "RUS", player: "Sergey Ignashevich", scored: true, notes: nil },
  { order: 4, team: "ESP", player: "Gerard Piqué",      scored: true,  notes: nil },
  { order: 5, team: "RUS", player: "Aleksandr Golovin", scored: true,  notes: nil },
  { order: 6, team: "ESP", player: "Koke",              scored: false, notes: "saved by Akinfeev" },
  { order: 7, team: "RUS", player: "Denis Cheryshev",   scored: true,  notes: nil },
  { order: 8, team: "ESP", player: "Iago Aspas",        scored: false, notes: "saved by Akinfeev" }
].freeze

# Match 52: Croatia 1-1 Denmark (Croatia won 3-2)
CRO_DEN_2018_SHOOTOUT = [
  { order: 1, team: "CRO", player: "Milan Badelj",         scored: false, notes: "hit the post" },
  { order: 2, team: "DEN", player: "Christian Eriksen",    scored: false, notes: "saved by Subašić" },
  { order: 3, team: "CRO", player: "Andrej Kramarić",      scored: true,  notes: nil },
  { order: 4, team: "DEN", player: "Lasse Schöne",         scored: false, notes: "saved by Subašić" },
  { order: 5, team: "CRO", player: "Luka Modrić",          scored: true,  notes: nil },
  { order: 6, team: "DEN", player: "Michael Krohn-Dehli",  scored: true,  notes: nil },
  { order: 7, team: "CRO", player: "Josip Pivarić",        scored: false, notes: "saved by Schmeichel" },
  { order: 8, team: "DEN", player: "Nicolai Jørgensen",    scored: false, notes: "saved by Subašić" },
  { order: 9, team: "CRO", player: "Ivan Rakitić",         scored: true,  notes: "won the shootout for Croatia" }
].freeze

# Match 56: Colombia 1-1 England (England won 4-3)
COL_ENG_2018_SHOOTOUT = [
  { order: 1, team: "ENG", player: "Harry Kane",        scored: true,  notes: nil },
  { order: 2, team: "COL", player: "Radamel Falcao",    scored: true,  notes: nil },
  { order: 3, team: "ENG", player: "Marcus Rashford",   scored: true,  notes: nil },
  { order: 4, team: "COL", player: "Juan Cuadrado",     scored: true,  notes: nil },
  { order: 5, team: "ENG", player: "Jordan Henderson",  scored: false, notes: "saved by Ospina" },
  { order: 6, team: "COL", player: "Luis Muriel",       scored: true,  notes: nil },
  { order: 7, team: "ENG", player: "Kieran Trippier",   scored: true,  notes: nil },
  { order: 8, team: "COL", player: "Mateus Uribe",      scored: false, notes: "hit the bar" },
  { order: 9, team: "ENG", player: "Eric Dier",         scored: true,  notes: "won the shootout for England" }
].freeze

# Match 60: Russia 2-2 Croatia (Croatia won 4-3)
RUS_CRO_2018_SHOOTOUT = [
  { order: 1, team: "RUS", player: "Fyodor Smolov",         scored: false, notes: "saved by Subašić" },
  { order: 2, team: "CRO", player: "Marcelo Brozović",      scored: true,  notes: nil },
  { order: 3, team: "RUS", player: "Aleksandr Yerokhin",    scored: true,  notes: nil },
  { order: 4, team: "CRO", player: "Mateo Kovačić",         scored: false, notes: "saved by Akinfeev" },
  { order: 5, team: "RUS", player: "Mário Fernandes",       scored: false, notes: "shot wide" },
  { order: 6, team: "CRO", player: "Luka Modrić",           scored: true,  notes: nil },
  { order: 7, team: "RUS", player: "Sergey Ignashevich",    scored: true,  notes: nil },
  { order: 8, team: "CRO", player: "Domagoj Vida",          scored: true,  notes: nil },
  { order: 9, team: "RUS", player: "Daler Kuzyaev",         scored: true,  notes: nil },
  { order: 10, team: "CRO", player: "Ivan Rakitić",         scored: true,  notes: "won the shootout for Croatia" }
].freeze

SHOOTOUTS_2018 = {
  51 => ESP_RUS_2018_SHOOTOUT,
  52 => CRO_DEN_2018_SHOOTOUT,
  56 => COL_ENG_2018_SHOOTOUT,
  60 => RUS_CRO_2018_SHOOTOUT
}.freeze

TOURNAMENT_SHOOTOUTS = {
  1986 => SHOOTOUTS_1986,
  2018 => SHOOTOUTS_2018,
  2022 => SHOOTOUTS_2022
}.freeze

TOURNAMENT_SHOOTOUTS.each do |year, shootouts|
  t_obj = Tournament.find_by!(year: year)
  shootouts.each do |match_number, kicks|
    match = Match.find_by!(tournament: t_obj, match_number: match_number)
    kicks.each do |kick|
      # Skip if the player isn't seeded — keeps the seed graceful.
      next unless Player.exists?(name: kick[:player])

      ShootoutKick.find_or_create_by!(match: match, kick_order: kick[:order]) do |sk|
        sk.team       = t!(kick[:team])
        sk.player     = player!(kick[:player])
        sk.was_scored = kick[:scored]
        sk.notes      = kick[:notes]
      end
    end
  end
end

puts "ShootoutKicks: #{ShootoutKick.count}"
