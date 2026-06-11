# FIFA's individual awards per tournament.
#
# Depends on: tournaments.rb, players.rb

def tournament_for(year) = Tournament.find_by!(year: year)
def player_for(name)     = Player.find_by!(name: name)

AWARDS = {
  1982 => [
    { type: :golden_ball,        player: "Paolo Rossi" },
    { type: :silver_ball,        player: "Falcão" },
    { type: :bronze_ball,        player: "Karl-Heinz Rummenigge" },
    { type: :golden_boot,        player: "Paolo Rossi",       notes: "6 goals" }
  ],
  1986 => [
    { type: :golden_ball,        player: "Diego Maradona" },
    { type: :silver_ball,        player: "Harald Schumacher" },
    { type: :bronze_ball,        player: "Preben Elkjær" },
    { type: :golden_boot,        player: "Gary Lineker",       notes: "6 goals" },
    { type: :silver_boot,        player: "Diego Maradona",     notes: "5 goals" },
    { type: :bronze_boot,        player: "Emilio Butragueño",  notes: "5 goals" }
  ],
  1990 => [
    { type: :golden_ball,        player: "Salvatore Schillaci" },
    { type: :silver_ball,        player: "Lothar Matthäus" },
    { type: :bronze_ball,        player: "Diego Maradona" },
    { type: :golden_boot,        player: "Salvatore Schillaci", notes: "6 goals" }
  ],
  1994 => [
    { type: :golden_ball,        player: "Romário" },
    { type: :silver_ball,        player: "Roberto Baggio" },
    { type: :bronze_ball,        player: "Hristo Stoichkov" },
    { type: :golden_boot,        player: "Oleg Salenko",     notes: "6 goals (shared with Stoichkov; tiebreaker on assists)" },
    { type: :golden_boot,        player: "Hristo Stoichkov", notes: "6 goals (shared)" }
  ],
  1998 => [
    { type: :golden_ball,        player: "Ronaldo" },
    { type: :silver_ball,        player: "Davor Šuker" },
    { type: :bronze_ball,        player: "Lilian Thuram" },
    { type: :golden_boot,        player: "Davor Šuker",      notes: "6 goals" }
  ],
  2002 => [
    { type: :golden_ball,        player: "Oliver Kahn" },
    { type: :silver_ball,        player: "Ronaldo" },
    { type: :bronze_ball,        player: "Myung-bo Hong" },
    { type: :golden_boot,        player: "Ronaldo",          notes: "8 goals" },
    { type: :golden_glove,       player: "Oliver Kahn" }
  ],
  2006 => [
    { type: :golden_ball,        player: "Zinedine Zidane" },
    { type: :silver_ball,        player: "Fabio Cannavaro" },
    { type: :bronze_ball,        player: "Andrea Pirlo" },
    { type: :golden_boot,        player: "Miroslav Klose",   notes: "5 goals" },
    { type: :golden_glove,       player: "Gianluigi Buffon" },
    { type: :best_young_player,  player: "Lukas Podolski" }
  ],
  2010 => [
    { type: :golden_ball,        player: "Diego Forlán" },
    { type: :silver_ball,        player: "Wesley Sneijder" },
    { type: :bronze_ball,        player: "David Villa" },
    { type: :golden_boot,        player: "Thomas Müller",    notes: "5 goals (tiebreaker on assists)" },
    { type: :golden_glove,       player: "Iker Casillas" },
    { type: :best_young_player,  player: "Thomas Müller" }
  ],
  2014 => [
    { type: :golden_ball,        player: "Lionel Messi" },
    { type: :silver_ball,        player: "Thomas Müller" },
    { type: :bronze_ball,        player: "Arjen Robben" },
    { type: :golden_boot,        player: "James Rodríguez",  notes: "6 goals" },
    { type: :silver_boot,        player: "Thomas Müller",    notes: "5 goals" },
    { type: :bronze_boot,        player: "Neymar",           notes: "4 goals (ahead of Messi/van Persie on assists tiebreaker)" },
    { type: :golden_glove,       player: "Manuel Neuer" },
    { type: :best_young_player,  player: "Paul Pogba" }
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
missing = []
AWARDS.each do |year, awards|
  t = tournament_for(year)
  awards.each do |attrs|
    player = Player.find_by(name: attrs[:player])
    if player.nil?
      missing << [year, attrs[:type], attrs[:player]]
      next
    end
    TournamentAward.find_or_create_by!(
      tournament: t,
      award_type: attrs[:type],
      player: player
    ) do |a|
      a.notes = attrs[:notes]
    end
    count += 1
  end
end

puts "TournamentAwards: #{TournamentAward.count} (target across all tournaments: #{count})"
if missing.any?
  puts "  Skipped #{missing.size} award(s) — player not found in DB:"
  missing.each { |y, t, p| puts "    #{y} #{t}: #{p}" }
end
