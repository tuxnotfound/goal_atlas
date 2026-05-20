# FIFA's individual awards per tournament.
#
# Depends on: tournaments.rb, players.rb

def tournament_for(year) = Tournament.find_by!(year: year)
def player_for(name)     = Player.find_by!(name: name)

AWARDS = {
  1986 => [
    { type: :golden_ball,        player: "Diego Maradona" },
    { type: :bronze_ball,        player: "Preben Elkjær" },
    { type: :golden_boot,        player: "Gary Lineker",       notes: "6 goals" },
    { type: :silver_boot,        player: "Diego Maradona",     notes: "5 goals" },
    { type: :bronze_boot,        player: "Emilio Butragueño",  notes: "5 goals" }
  ],
  2018 => [
    { type: :golden_ball,        player: "Luka Modrić" },
    { type: :silver_ball,        player: "Eden Hazard" },
    { type: :bronze_ball,        player: "Antoine Griezmann" },
    { type: :golden_boot,        player: "Harry Kane",         notes: "6 goals" },
    { type: :silver_boot,        player: "Antoine Griezmann",  notes: "4 goals" },
    { type: :bronze_boot,        player: "Romelu Lukaku",      notes: "4 goals" },
    { type: :best_young_player,  player: "Kylian Mbappé" }
  ],
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
