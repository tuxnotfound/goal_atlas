# Penalty shootout of the 2022 World Cup final.
# Argentina won the shootout 4-2: Messi/Dybala/Paredes/Montiel scored; Coman saved,
# Tchouaméni missed wide. Mbappé and Kolo Muani scored for France.
#
# QF shootouts (NED-ARG, CRO-BRA) are intentionally skipped for now — backfill later.
#
# Depends on: matches.rb, players.rb, teams.rb

final = Match.find_by!(tournament: Tournament.find_by!(year: 2022), match_number: 64)

def player!(name) = Player.find_by!(name: name)
def t!(code)      = Team.find_by!(fifa_code: code)

FINAL_SHOOTOUT = [
  { order: 1, team: "FRA", player: "Kylian Mbappé",     scored: true,  notes: nil },
  { order: 2, team: "ARG", player: "Lionel Messi",      scored: true,  notes: nil },
  { order: 3, team: "FRA", player: "Kingsley Coman",    scored: false, notes: "saved by Emiliano Martínez" },
  { order: 4, team: "ARG", player: "Paulo Dybala",      scored: true,  notes: nil },
  { order: 5, team: "FRA", player: "Aurélien Tchouaméni", scored: false, notes: "missed wide of the post" },
  { order: 6, team: "ARG", player: "Leandro Paredes",   scored: true,  notes: nil },
  { order: 7, team: "FRA", player: "Randal Kolo Muani", scored: true,  notes: nil },
  { order: 8, team: "ARG", player: "Gonzalo Montiel",   scored: true,  notes: "won the World Cup for Argentina" }
].freeze

FINAL_SHOOTOUT.each do |kick|
  ShootoutKick.find_or_create_by!(match: final, kick_order: kick[:order]) do |sk|
    sk.team       = t!(kick[:team])
    sk.player     = player!(kick[:player])
    sk.was_scored = kick[:scored]
    sk.notes      = kick[:notes]
  end
end

puts "ShootoutKicks (final): #{ShootoutKick.where(match: final).count} (target: 8)"
