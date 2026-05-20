# Penalty shootouts of the 2022 World Cup.
# - Match 53 (Japan vs Croatia, R16): Croatia won 3-1.
# - Match 55 (Morocco vs Spain, R16): Morocco won 3-0.
# - Match 64 (Argentina vs France, Final): Argentina won 4-2.
#
# QF shootouts (Match 57 NED-ARG, Match 58 CRO-BRA) are still TODO — backfill later.
#
# Depends on: matches.rb, players.rb, teams.rb

tournament = Tournament.find_by!(year: 2022)

def player!(name) = Player.find_by!(name: name)
def t!(code)      = Team.find_by!(fifa_code: code)

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
FINAL_SHOOTOUT = [
  { order: 1, team: "FRA", player: "Kylian Mbappé",       scored: true,  notes: nil },
  { order: 2, team: "ARG", player: "Lionel Messi",        scored: true,  notes: nil },
  { order: 3, team: "FRA", player: "Kingsley Coman",      scored: false, notes: "saved by Emiliano Martínez" },
  { order: 4, team: "ARG", player: "Paulo Dybala",        scored: true,  notes: nil },
  { order: 5, team: "FRA", player: "Aurélien Tchouaméni", scored: false, notes: "missed wide of the post" },
  { order: 6, team: "ARG", player: "Leandro Paredes",     scored: true,  notes: nil },
  { order: 7, team: "FRA", player: "Randal Kolo Muani",   scored: true,  notes: nil },
  { order: 8, team: "ARG", player: "Gonzalo Montiel",     scored: true,  notes: "won the World Cup for Argentina" }
].freeze

SHOOTOUTS = {
  53 => JPN_CRO_SHOOTOUT,
  55 => MAR_ESP_SHOOTOUT,
  64 => FINAL_SHOOTOUT
}.freeze

SHOOTOUTS.each do |match_number, kicks|
  match = Match.find_by!(tournament: tournament, match_number: match_number)
  kicks.each do |kick|
    ShootoutKick.find_or_create_by!(match: match, kick_order: kick[:order]) do |sk|
      sk.team       = t!(kick[:team])
      sk.player     = player!(kick[:player])
      sk.was_scored = kick[:scored]
      sk.notes      = kick[:notes]
    end
  end
end

puts "ShootoutKicks: #{ShootoutKick.joins(:match).where(matches: { tournament_id: tournament.id }).count} (target: 22)"
