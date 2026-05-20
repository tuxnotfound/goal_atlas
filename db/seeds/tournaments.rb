# FIFA World Cup tournament records.

TOURNAMENTS = [
  {
    year: 1986, name: "FIFA World Cup 1986",
    host_countries: ["Mexico"],
    start_date: Date.new(1986, 5, 31), end_date: Date.new(1986, 6, 29),
    total_matches: 52, total_goals: 132,
    winner: "ARG", runner_up: "FRG", third: "FRA", fourth: "BEL"
  },
  {
    year: 2018, name: "FIFA World Cup 2018",
    host_countries: ["Russia"],
    start_date: Date.new(2018, 6, 14), end_date: Date.new(2018, 7, 15),
    total_matches: 64, total_goals: 169,
    winner: "FRA", runner_up: "CRO", third: "BEL", fourth: "ENG"
  },
  {
    year: 2022, name: "FIFA World Cup 2022",
    host_countries: ["Qatar"],
    start_date: Date.new(2022, 11, 20), end_date: Date.new(2022, 12, 18),
    total_matches: 64, total_goals: 172,
    winner: "ARG", runner_up: "FRA", third: "CRO", fourth: "MAR"
  }
].freeze

TOURNAMENTS.each do |attrs|
  tournament = Tournament.find_or_create_by!(year: attrs[:year]) do |t|
    t.name = attrs[:name]
    t.host_countries = attrs[:host_countries]
    t.start_date = attrs[:start_date]
    t.end_date   = attrs[:end_date]
    t.total_matches = attrs[:total_matches]
    t.total_goals = attrs[:total_goals]
  end

  tournament.update!(
    winner_team:       Team.find_by!(fifa_code: attrs[:winner]),
    runner_up_team:    Team.find_by!(fifa_code: attrs[:runner_up]),
    third_place_team:  Team.find_by!(fifa_code: attrs[:third]),
    fourth_place_team: Team.find_by!(fifa_code: attrs[:fourth])
  )
end

puts "Tournaments: #{Tournament.count}"
