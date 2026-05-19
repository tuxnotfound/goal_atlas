# The 32 national teams that competed at the 2022 FIFA World Cup.
# country_code uses the FIFA 3-letter code (football-context standard).
# Idempotent: find_or_create_by! on fifa_code, which is unique enough for teams.

TEAMS_2022 = [
  # UEFA — 13
  { name: "England",      country_code: "ENG", fifa_code: "ENG", flag_emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", confederation: :uefa },
  { name: "France",       country_code: "FRA", fifa_code: "FRA", flag_emoji: "🇫🇷", confederation: :uefa },
  { name: "Germany",      country_code: "GER", fifa_code: "GER", flag_emoji: "🇩🇪", confederation: :uefa },
  { name: "Spain",        country_code: "ESP", fifa_code: "ESP", flag_emoji: "🇪🇸", confederation: :uefa },
  { name: "Belgium",      country_code: "BEL", fifa_code: "BEL", flag_emoji: "🇧🇪", confederation: :uefa },
  { name: "Netherlands",  country_code: "NED", fifa_code: "NED", flag_emoji: "🇳🇱", confederation: :uefa },
  { name: "Portugal",     country_code: "POR", fifa_code: "POR", flag_emoji: "🇵🇹", confederation: :uefa },
  { name: "Croatia",      country_code: "CRO", fifa_code: "CRO", flag_emoji: "🇭🇷", confederation: :uefa },
  { name: "Switzerland",  country_code: "SUI", fifa_code: "SUI", flag_emoji: "🇨🇭", confederation: :uefa },
  { name: "Wales",        country_code: "WAL", fifa_code: "WAL", flag_emoji: "🏴󠁧󠁢󠁷󠁬󠁳󠁿", confederation: :uefa },
  { name: "Poland",       country_code: "POL", fifa_code: "POL", flag_emoji: "🇵🇱", confederation: :uefa },
  { name: "Denmark",      country_code: "DEN", fifa_code: "DEN", flag_emoji: "🇩🇰", confederation: :uefa },
  { name: "Serbia",       country_code: "SRB", fifa_code: "SRB", flag_emoji: "🇷🇸", confederation: :uefa },

  # CONMEBOL — 4
  { name: "Argentina",    country_code: "ARG", fifa_code: "ARG", flag_emoji: "🇦🇷", confederation: :conmebol },
  { name: "Brazil",       country_code: "BRA", fifa_code: "BRA", flag_emoji: "🇧🇷", confederation: :conmebol },
  { name: "Uruguay",      country_code: "URU", fifa_code: "URU", flag_emoji: "🇺🇾", confederation: :conmebol },
  { name: "Ecuador",      country_code: "ECU", fifa_code: "ECU", flag_emoji: "🇪🇨", confederation: :conmebol },

  # CONCACAF — 4
  { name: "Mexico",       country_code: "MEX", fifa_code: "MEX", flag_emoji: "🇲🇽", confederation: :concacaf },
  { name: "United States", country_code: "USA", fifa_code: "USA", flag_emoji: "🇺🇸", confederation: :concacaf },
  { name: "Costa Rica",   country_code: "CRC", fifa_code: "CRC", flag_emoji: "🇨🇷", confederation: :concacaf },
  { name: "Canada",       country_code: "CAN", fifa_code: "CAN", flag_emoji: "🇨🇦", confederation: :concacaf },

  # AFC — 6
  { name: "Qatar",        country_code: "QAT", fifa_code: "QAT", flag_emoji: "🇶🇦", confederation: :afc },
  { name: "Iran",         country_code: "IRN", fifa_code: "IRN", flag_emoji: "🇮🇷", confederation: :afc },
  { name: "Saudi Arabia", country_code: "KSA", fifa_code: "KSA", flag_emoji: "🇸🇦", confederation: :afc },
  { name: "Japan",        country_code: "JPN", fifa_code: "JPN", flag_emoji: "🇯🇵", confederation: :afc },
  { name: "South Korea",  country_code: "KOR", fifa_code: "KOR", flag_emoji: "🇰🇷", confederation: :afc },
  { name: "Australia",    country_code: "AUS", fifa_code: "AUS", flag_emoji: "🇦🇺", confederation: :afc },

  # CAF — 5
  { name: "Senegal",      country_code: "SEN", fifa_code: "SEN", flag_emoji: "🇸🇳", confederation: :caf },
  { name: "Tunisia",      country_code: "TUN", fifa_code: "TUN", flag_emoji: "🇹🇳", confederation: :caf },
  { name: "Morocco",      country_code: "MAR", fifa_code: "MAR", flag_emoji: "🇲🇦", confederation: :caf },
  { name: "Cameroon",     country_code: "CMR", fifa_code: "CMR", flag_emoji: "🇨🇲", confederation: :caf },
  { name: "Ghana",        country_code: "GHA", fifa_code: "GHA", flag_emoji: "🇬🇭", confederation: :caf }
].freeze

TEAMS_2022.each do |attrs|
  Team.find_or_create_by!(fifa_code: attrs[:fifa_code]) do |team|
    team.assign_attributes(attrs)
  end
end

puts "Teams: #{Team.count} (target: 32)"
