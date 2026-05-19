# The 8 venues used at the 2022 FIFA World Cup in Qatar.
# Coordinates are approximate; capacities are the 2022 tournament-time figures.

STADIUMS_2022 = [
  {
    name: "Lusail Iconic Stadium", city: "Lusail", country: "Qatar", country_code: "QA",
    latitude: 25.4242, longitude: 51.4906, current_capacity: 88_966,
    notes: "Hosted the 2022 World Cup final (Argentina 3-3 France, Argentina won 4-2 on penalties)."
  },
  {
    name: "Al Bayt Stadium", city: "Al Khor", country: "Qatar", country_code: "QA",
    latitude: 25.6589, longitude: 51.4869, current_capacity: 68_895,
    notes: "Hosted the opening match and one semi-final."
  },
  {
    name: "Stadium 974", city: "Doha", country: "Qatar", country_code: "QA",
    latitude: 25.2895, longitude: 51.5530, current_capacity: 44_089,
    notes: "Built from 974 shipping containers; dismantled after the tournament."
  },
  {
    name: "Khalifa International Stadium", city: "Al Rayyan", country: "Qatar", country_code: "QA",
    latitude: 25.2638, longitude: 51.4499, current_capacity: 45_857,
    notes: "Hosted the third-place playoff."
  },
  {
    name: "Education City Stadium", city: "Al Rayyan", country: "Qatar", country_code: "QA",
    latitude: 25.3110, longitude: 51.4248, current_capacity: 44_667
  },
  {
    name: "Ahmad bin Ali Stadium", city: "Al Rayyan", country: "Qatar", country_code: "QA",
    latitude: 25.3389, longitude: 51.3445, current_capacity: 44_740
  },
  {
    name: "Al Janoub Stadium", city: "Al Wakrah", country: "Qatar", country_code: "QA",
    latitude: 25.1467, longitude: 51.5934, current_capacity: 44_325
  },
  {
    name: "Al Thumama Stadium", city: "Doha", country: "Qatar", country_code: "QA",
    latitude: 25.2349, longitude: 51.5469, current_capacity: 44_400
  }
].freeze

STADIUMS_2022.each do |attrs|
  Stadium.find_or_create_by!(name: attrs[:name]) do |stadium|
    stadium.assign_attributes(attrs)
  end
end

puts "Stadiums: #{Stadium.count} (target: 8)"
