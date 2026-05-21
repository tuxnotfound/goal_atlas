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

# Historical and additional teams needed to seed older tournaments (1986, 2018, etc.).
HISTORICAL_TEAMS = [
  # === 1986 squad participants not in TEAMS_2022 ===
  { name: "West Germany",    country_code: "FRG", fifa_code: "FRG", flag_emoji: "🇩🇪", confederation: :uefa,
    active_from: 1908, active_until: 1990, successor_fifa_code: "GER" },
  { name: "Soviet Union",    country_code: "URS", fifa_code: "URS", flag_emoji: "🇷🇺", confederation: :uefa,
    active_from: 1924, active_until: 1991 },
  { name: "Italy",           country_code: "ITA", fifa_code: "ITA", flag_emoji: "🇮🇹", confederation: :uefa },
  { name: "Hungary",         country_code: "HUN", fifa_code: "HUN", flag_emoji: "🇭🇺", confederation: :uefa },
  { name: "Bulgaria",        country_code: "BUL", fifa_code: "BUL", flag_emoji: "🇧🇬", confederation: :uefa },
  { name: "Scotland",        country_code: "SCO", fifa_code: "SCO", flag_emoji: "🏴󠁧󠁢󠁳󠁣󠁴󠁿", confederation: :uefa },
  { name: "Northern Ireland", country_code: "NIR", fifa_code: "NIR", flag_emoji: "🇬🇧", confederation: :uefa },
  { name: "Paraguay",        country_code: "PAR", fifa_code: "PAR", flag_emoji: "🇵🇾", confederation: :conmebol },
  { name: "Iraq",            country_code: "IRQ", fifa_code: "IRQ", flag_emoji: "🇮🇶", confederation: :afc },
  { name: "Algeria",         country_code: "ALG", fifa_code: "ALG", flag_emoji: "🇩🇿", confederation: :caf },

  # === 2018 squad participants not in TEAMS_2022 ===
  { name: "Russia",          country_code: "RUS", fifa_code: "RUS", flag_emoji: "🇷🇺", confederation: :uefa },
  { name: "Egypt",            country_code: "EGY", fifa_code: "EGY", flag_emoji: "🇪🇬", confederation: :caf },
  { name: "Peru",             country_code: "PER", fifa_code: "PER", flag_emoji: "🇵🇪", confederation: :conmebol },
  { name: "Iceland",          country_code: "ISL", fifa_code: "ISL", flag_emoji: "🇮🇸", confederation: :uefa },
  { name: "Nigeria",          country_code: "NGA", fifa_code: "NGA", flag_emoji: "🇳🇬", confederation: :caf },
  { name: "Sweden",           country_code: "SWE", fifa_code: "SWE", flag_emoji: "🇸🇪", confederation: :uefa },
  { name: "Panama",           country_code: "PAN", fifa_code: "PAN", flag_emoji: "🇵🇦", confederation: :concacaf },
  { name: "Colombia",         country_code: "COL", fifa_code: "COL", flag_emoji: "🇨🇴", confederation: :conmebol },

  # === 2014 squad participants not already listed ===
  { name: "Bosnia and Herzegovina", country_code: "BIH", fifa_code: "BIH", flag_emoji: "🇧🇦", confederation: :uefa },
  { name: "Chile",                  country_code: "CHI", fifa_code: "CHI", flag_emoji: "🇨🇱", confederation: :conmebol },
  { name: "Greece",                 country_code: "GRE", fifa_code: "GRE", flag_emoji: "🇬🇷", confederation: :uefa },
  { name: "Honduras",               country_code: "HON", fifa_code: "HON", flag_emoji: "🇭🇳", confederation: :concacaf },
  { name: "Ivory Coast",            country_code: "CIV", fifa_code: "CIV", flag_emoji: "🇨🇮", confederation: :caf },

  # === 1930 squad participants not already listed ===
  { name: "Bolivia",         country_code: "BOL", fifa_code: "BOL", flag_emoji: "🇧🇴", confederation: :conmebol },
  { name: "Romania",         country_code: "ROU", fifa_code: "ROU", flag_emoji: "🇷🇴", confederation: :uefa },
  { name: "Yugoslavia",      country_code: "YUG", fifa_code: "YUG", flag_emoji: "🇷🇸", confederation: :uefa,
    active_from: 1919, active_until: 1992 },

  # === Pre-war (1934-1938) participants ===
  { name: "Austria",            country_code: "AUT", fifa_code: "AUT", flag_emoji: "🇦🇹", confederation: :uefa },
  { name: "Czechoslovakia",     country_code: "TCH", fifa_code: "TCH", flag_emoji: "🇨🇿", confederation: :uefa,
    active_from: 1920, active_until: 1992, successor_fifa_code: "CZE" },
  { name: "Cuba",               country_code: "CUB", fifa_code: "CUB", flag_emoji: "🇨🇺", confederation: :concacaf },
  { name: "Dutch East Indies",  country_code: "DEI", fifa_code: "DEI", flag_emoji: "🇮🇩", confederation: :afc,
    active_from: 1931, active_until: 1949 },

  # === 1950-1970s additions ===
  { name: "Haiti",              country_code: "HAI", fifa_code: "HAI", flag_emoji: "🇭🇹", confederation: :concacaf },
  { name: "Israel",             country_code: "ISR", fifa_code: "ISR", flag_emoji: "🇮🇱", confederation: :uefa },
  { name: "Norway",             country_code: "NOR", fifa_code: "NOR", flag_emoji: "🇳🇴", confederation: :uefa },
  { name: "Turkey",             country_code: "TUR", fifa_code: "TUR", flag_emoji: "🇹🇷", confederation: :uefa },
  { name: "Zaire",              country_code: "ZAI", fifa_code: "ZAI", flag_emoji: "🇨🇩", confederation: :caf,
    active_from: 1964, active_until: 1997 },
  { name: "East Germany",       country_code: "GDR", fifa_code: "GDR", flag_emoji: "🇩🇪", confederation: :uefa,
    active_from: 1949, active_until: 1990, successor_fifa_code: "GER" },
  { name: "El Salvador",        country_code: "SLV", fifa_code: "SLV", flag_emoji: "🇸🇻", confederation: :concacaf },

  # === 1982-1994 additions ===
  { name: "New Zealand",        country_code: "NZL", fifa_code: "NZL", flag_emoji: "🇳🇿", confederation: :ofc },
  { name: "Kuwait",             country_code: "KUW", fifa_code: "KUW", flag_emoji: "🇰🇼", confederation: :afc },
  { name: "United Arab Emirates", country_code: "UAE", fifa_code: "UAE", flag_emoji: "🇦🇪", confederation: :afc },
  { name: "Republic of Ireland", country_code: "IRL", fifa_code: "IRL", flag_emoji: "🇮🇪", confederation: :uefa },

  # === 1998-2010 additions ===
  { name: "Jamaica",            country_code: "JAM", fifa_code: "JAM", flag_emoji: "🇯🇲", confederation: :concacaf },
  { name: "South Africa",       country_code: "RSA", fifa_code: "RSA", flag_emoji: "🇿🇦", confederation: :caf },
  { name: "Slovenia",           country_code: "SVN", fifa_code: "SVN", flag_emoji: "🇸🇮", confederation: :uefa },
  { name: "China",              country_code: "CHN", fifa_code: "CHN", flag_emoji: "🇨🇳", confederation: :afc },
  { name: "Serbia and Montenegro", country_code: "SCG", fifa_code: "SCG", flag_emoji: "🇷🇸", confederation: :uefa,
    active_from: 2003, active_until: 2006 },
  { name: "Ukraine",            country_code: "UKR", fifa_code: "UKR", flag_emoji: "🇺🇦", confederation: :uefa },
  { name: "Trinidad and Tobago", country_code: "TRI", fifa_code: "TRI", flag_emoji: "🇹🇹", confederation: :concacaf },
  { name: "Togo",               country_code: "TGO", fifa_code: "TGO", flag_emoji: "🇹🇬", confederation: :caf },
  { name: "Slovakia",           country_code: "SVK", fifa_code: "SVK", flag_emoji: "🇸🇰", confederation: :uefa },
  { name: "North Korea",        country_code: "PRK", fifa_code: "PRK", flag_emoji: "🇰🇵", confederation: :afc },
  { name: "Angola",             country_code: "ANG", fifa_code: "ANG", flag_emoji: "🇦🇴", confederation: :caf },
  { name: "Czech Republic",     country_code: "CZE", fifa_code: "CZE", flag_emoji: "🇨🇿", confederation: :uefa }
].freeze

(TEAMS_2022 + HISTORICAL_TEAMS).each do |attrs|
  Team.find_or_create_by!(fifa_code: attrs[:fifa_code]) do |team|
    team.assign_attributes(attrs.except(:successor_fifa_code, :active_from, :active_until))
    team.active_from  = attrs[:active_from]
    team.active_until = attrs[:active_until]
  end
end

# Link historical successors (e.g., West Germany → Germany).
HISTORICAL_TEAMS.each do |attrs|
  next unless attrs[:successor_fifa_code]
  team      = Team.find_by!(fifa_code: attrs[:fifa_code])
  successor = Team.find_by!(fifa_code: attrs[:successor_fifa_code])
  team.update!(successor_team: successor) if team.successor_team_id.nil?
end

puts "Teams: #{Team.count} (target: #{TEAMS_2022.size + HISTORICAL_TEAMS.size})"
