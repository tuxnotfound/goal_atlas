# The 2022 FIFA World Cup in Qatar.
# Podium teams are wired in after Team records exist.

tournament = Tournament.find_or_create_by!(year: 2022) do |t|
  t.name = "FIFA World Cup 2022"
  t.host_countries = ["Qatar"]
  t.start_date = Date.new(2022, 11, 20)
  t.end_date   = Date.new(2022, 12, 18)
  t.total_matches = 64
  t.total_goals = 172
end

tournament.update!(
  winner_team:       Team.find_by!(fifa_code: "ARG"),
  runner_up_team:    Team.find_by!(fifa_code: "FRA"),
  third_place_team:  Team.find_by!(fifa_code: "CRO"),
  fourth_place_team: Team.find_by!(fifa_code: "MAR")
)

puts "Tournament: #{tournament.name} — winner: #{tournament.winner_team.name}"
