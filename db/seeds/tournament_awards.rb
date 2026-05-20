# FIFA's individual awards per tournament.
#
# Award types:
#   - golden/silver/bronze_ball: Adidas Golden/Silver/Bronze Ball (best player)
#   - golden/silver/bronze_boot: Adidas Golden/Silver/Bronze Boot (top scorer)
#   - golden_glove: Lev Yashin Trophy (best goalkeeper)
#   - best_young_player: Hyundai Young Player Award (best U21 player)
#
# Depends on: tournaments.rb, players.rb

def tournament_for(year) = Tournament.find_by!(year: year)
def player_for(name)     = Player.find_by!(name: name)

AWARDS = {
  2022 => [
    { type: :golden_ball,        player: "Lionel Messi" },
    { type: :silver_ball,        player: "Kylian Mbappé" },
    { type: :bronze_ball,        player: "Luka Modrić" },
    { type: :golden_boot,        player: "Kylian Mbappé",   notes: "8 goals" },
    { type: :silver_boot,        player: "Lionel Messi",    notes: "7 goals" },
    { type: :bronze_boot,        player: "Julián Álvarez",  notes: "4 goals (ahead of Giroud on assists tiebreaker)" },
    { type: :golden_glove,       player: "Emiliano Martínez" },
    { type: :best_young_player,  player: "Enzo Fernández" }
  ]
}.freeze

count = 0
AWARDS.each do |year, awards|
  t = tournament_for(year)
  awards.each do |attrs|
    TournamentAward.find_or_create_by!(
      tournament: t,
      award_type: attrs[:type],
      player: player_for(attrs[:player])
    ) do |a|
      a.notes = attrs[:notes]
    end
    count += 1
  end
end

puts "TournamentAwards: #{TournamentAward.count} (target across all tournaments: #{count})"
