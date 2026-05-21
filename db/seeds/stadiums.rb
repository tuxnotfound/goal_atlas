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

# The 12 venues used at the 1986 FIFA World Cup in Mexico.
STADIUMS_1986 = [
  { name: "Estadio Azteca", city: "Mexico City", country: "Mexico", country_code: "MX",
    latitude: 19.3029, longitude: -99.1505, current_capacity: 87_000,
    notes: "Hosted the 1986 World Cup final (Argentina 3-2 West Germany) and Maradona's two iconic goals vs England in the QF. Also hosted the 1970 final." },
  { name: "Estadio Olímpico Universitario", city: "Mexico City", country: "Mexico", country_code: "MX",
    latitude: 19.3320, longitude: -99.1854, current_capacity: 72_000 },
  { name: "Estadio Cuauhtémoc", city: "Puebla", country: "Mexico", country_code: "MX",
    latitude: 19.0411, longitude: -98.2305, current_capacity: 51_726 },
  { name: "Estadio Jalisco", city: "Guadalajara", country: "Mexico", country_code: "MX",
    latitude: 20.7012, longitude: -103.3349, current_capacity: 55_020 },
  { name: "Estadio Tres de Marzo", city: "Zapopan", country: "Mexico", country_code: "MX",
    latitude: 20.7383, longitude: -103.4480, current_capacity: 30_015 },
  { name: "Estadio Tecnológico", city: "Monterrey", country: "Mexico", country_code: "MX",
    latitude: 25.6817, longitude: -100.3170, current_capacity: 38_000,
    notes: "Demolished in 2017." },
  { name: "Estadio Universitario (Monterrey)", city: "Monterrey", country: "Mexico", country_code: "MX",
    latitude: 25.7227, longitude: -100.3097, current_capacity: 41_615 },
  { name: "Estadio Corregidora", city: "Querétaro", country: "Mexico", country_code: "MX",
    latitude: 20.5849, longitude: -100.4253, current_capacity: 33_000 },
  { name: "Estadio Nemesio Díez", city: "Toluca", country: "Mexico", country_code: "MX",
    latitude: 19.2879, longitude: -99.6711, current_capacity: 30_000 },
  { name: "Estadio Sergio León Chávez", city: "Irapuato", country: "Mexico", country_code: "MX",
    latitude: 20.6816, longitude: -101.3514, current_capacity: 26_500 },
  { name: "Estadio Nou Camp", city: "León", country: "Mexico", country_code: "MX",
    latitude: 21.1232, longitude: -101.6700, current_capacity: 33_943 },
  { name: "Estadio Neza 86", city: "Nezahualcóyotl", country: "Mexico", country_code: "MX",
    latitude: 19.3915, longitude: -98.9961, current_capacity: 28_000,
    notes: "Demolished in 2007." }
].freeze

STADIUMS_1986.each do |attrs|
  Stadium.find_or_create_by!(name: attrs[:name]) do |stadium|
    stadium.assign_attributes(attrs)
  end
end

# The 12 venues used at the 2018 FIFA World Cup in Russia.
STADIUMS_2018 = [
  { name: "Luzhniki Stadium", city: "Moscow", country: "Russia", country_code: "RU",
    latitude: 55.7158, longitude: 37.5536, current_capacity: 81_000,
    notes: "Hosted the 2018 World Cup final (France 4-2 Croatia)." },
  { name: "Otkrytie Arena", city: "Moscow", country: "Russia", country_code: "RU",
    latitude: 55.8181, longitude: 37.4399, current_capacity: 45_360 },
  { name: "Saint Petersburg Stadium", city: "Saint Petersburg", country: "Russia", country_code: "RU",
    latitude: 59.9728, longitude: 30.2208, current_capacity: 64_287 },
  { name: "Fisht Olympic Stadium", city: "Sochi", country: "Russia", country_code: "RU",
    latitude: 43.4015, longitude: 39.9573, current_capacity: 44_287 },
  { name: "Volgograd Arena", city: "Volgograd", country: "Russia", country_code: "RU",
    latitude: 48.7350, longitude: 44.4727, current_capacity: 45_568 },
  { name: "Kazan Arena", city: "Kazan", country: "Russia", country_code: "RU",
    latitude: 55.8203, longitude: 49.1610, current_capacity: 45_379 },
  { name: "Mordovia Arena", city: "Saransk", country: "Russia", country_code: "RU",
    latitude: 54.1925, longitude: 45.1857, current_capacity: 44_442 },
  { name: "Nizhny Novgorod Stadium", city: "Nizhny Novgorod", country: "Russia", country_code: "RU",
    latitude: 56.3389, longitude: 43.9788, current_capacity: 44_899 },
  { name: "Rostov Arena", city: "Rostov-on-Don", country: "Russia", country_code: "RU",
    latitude: 47.2086, longitude: 39.7405, current_capacity: 45_000 },
  { name: "Samara Arena", city: "Samara", country: "Russia", country_code: "RU",
    latitude: 53.2839, longitude: 50.2317, current_capacity: 44_918 },
  { name: "Ekaterinburg Arena", city: "Yekaterinburg", country: "Russia", country_code: "RU",
    latitude: 56.8329, longitude: 60.5688, current_capacity: 35_696 },
  { name: "Kaliningrad Stadium", city: "Kaliningrad", country: "Russia", country_code: "RU",
    latitude: 54.6938, longitude: 20.5337, current_capacity: 35_212 }
].freeze

STADIUMS_2018.each do |attrs|
  Stadium.find_or_create_by!(name: attrs[:name]) do |stadium|
    stadium.assign_attributes(attrs)
  end
end

# The 12 venues used at the 2014 FIFA World Cup in Brazil.
STADIUMS_2014 = [
  { name: "Estádio do Maracanã", city: "Rio de Janeiro", country: "Brazil", country_code: "BR",
    latitude: -22.9122, longitude: -43.2302, current_capacity: 78_838,
    notes: "Hosted the 2014 World Cup final (Germany 1-0 Argentina, a.e.t.). Also hosted the 1950 final." },
  { name: "Estádio Mineirão", city: "Belo Horizonte", country: "Brazil", country_code: "BR",
    latitude: -19.8657, longitude: -43.9710, current_capacity: 61_846,
    notes: "Hosted the 7-1 Germany–Brazil semi-final." },
  { name: "Arena Corinthians", city: "São Paulo", country: "Brazil", country_code: "BR",
    latitude: -23.5453, longitude: -46.4744, current_capacity: 49_000,
    notes: "Hosted the opening match (Brazil 3-1 Croatia)." },
  { name: "Estádio Nacional", city: "Brasília", country: "Brazil", country_code: "BR",
    latitude: -15.7836, longitude: -47.8990, current_capacity: 69_349,
    notes: "Also known as Estádio Mané Garrincha." },
  { name: "Estádio Castelão", city: "Fortaleza", country: "Brazil", country_code: "BR",
    latitude: -3.8073, longitude: -38.5223, current_capacity: 63_903 },
  { name: "Arena Fonte Nova", city: "Salvador", country: "Brazil", country_code: "BR",
    latitude: -12.9789, longitude: -38.5044, current_capacity: 51_708 },
  { name: "Arena Pernambuco", city: "Recife", country: "Brazil", country_code: "BR",
    latitude: -8.0388, longitude: -35.0119, current_capacity: 44_248 },
  { name: "Arena da Amazônia", city: "Manaus", country: "Brazil", country_code: "BR",
    latitude: -3.0833, longitude: -60.0271, current_capacity: 40_549 },
  { name: "Estádio Beira-Rio", city: "Porto Alegre", country: "Brazil", country_code: "BR",
    latitude: -30.0651, longitude: -51.2358, current_capacity: 50_287 },
  { name: "Arena Pantanal", city: "Cuiabá", country: "Brazil", country_code: "BR",
    latitude: -15.6033, longitude: -56.1196, current_capacity: 41_390 },
  { name: "Arena das Dunas", city: "Natal", country: "Brazil", country_code: "BR",
    latitude: -5.8290, longitude: -35.2129, current_capacity: 31_375 },
  { name: "Arena da Baixada", city: "Curitiba", country: "Brazil", country_code: "BR",
    latitude: -25.4485, longitude: -49.2767, current_capacity: 42_372 }
].freeze

STADIUMS_2014.each do |attrs|
  Stadium.find_or_create_by!(name: attrs[:name]) do |stadium|
    stadium.assign_attributes(attrs)
  end
end

# The 3 venues used at the 1930 FIFA World Cup in Uruguay — all in Montevideo.
STADIUMS_1930 = [
  { name: "Estadio Centenario", city: "Montevideo", country: "Uruguay", country_code: "UY",
    latitude: -34.8941, longitude: -56.1525, current_capacity: 60_235,
    notes: "Built for the 1930 World Cup; hosted the final (Uruguay 4-2 Argentina). Now a FIFA Historic Football Monument." },
  { name: "Estadio Gran Parque Central", city: "Montevideo", country: "Uruguay", country_code: "UY",
    latitude: -34.8956, longitude: -56.1844, current_capacity: 30_000,
    notes: "Hosted the opening match (Uruguay's home of Club Nacional)." },
  { name: "Estadio Pocitos", city: "Montevideo", country: "Uruguay", country_code: "UY",
    latitude: -34.9145, longitude: -56.1572, current_capacity: 1_000,
    notes: "Hosted the first match of the tournament (USA 3-0 Belgium). Demolished in 1940." }
].freeze

STADIUMS_1930.each do |attrs|
  Stadium.find_or_create_by!(name: attrs[:name]) do |stadium|
    stadium.assign_attributes(attrs)
  end
end

puts "Stadiums: #{Stadium.count} (target: #{STADIUMS_2022.size + STADIUMS_1986.size + STADIUMS_2018.size + STADIUMS_2014.size + STADIUMS_1930.size})"
