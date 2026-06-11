# Seeds WC2026: Tournament + 5 new teams + 15 new stadiums + 72 scheduled
# group-stage matches.
#
# Reads from db/data/wc2026/{groups,fixtures}.yml. Idempotent — re-running
# only fills in what's missing, never duplicates.
#
# Knockout matches (32) are intentionally NOT seeded; teams are unknown until
# group standings determine the bracket. The post-tournament sync task adds
# them as group stage concludes.

require "yaml"

DATA_DIR = Rails.root.join("db/data/wc2026")
GROUPS   = YAML.load_file(DATA_DIR.join("groups.yml"))
FIXTURES = YAML.load_file(DATA_DIR.join("fixtures.yml"), permitted_classes: [Date])

# --- New teams (5) ---------------------------------------------------------
# Curaçao, Cape Verde, Jordan, DR Congo, Uzbekistan — all first-time
# qualifiers (except Qatar, which is already in the DB from 2022).

WC2026_NEW_TEAMS = [
  { name: "Curaçao",     country_code: "CUW", fifa_code: "CUW", flag_emoji: "🇨🇼", confederation: :concacaf },
  { name: "Cape Verde",  country_code: "CPV", fifa_code: "CPV", flag_emoji: "🇨🇻", confederation: :caf },
  { name: "Jordan",      country_code: "JOR", fifa_code: "JOR", flag_emoji: "🇯🇴", confederation: :afc },
  { name: "DR Congo",    country_code: "COD", fifa_code: "COD", flag_emoji: "🇨🇩", confederation: :caf },
  { name: "Uzbekistan",  country_code: "UZB", fifa_code: "UZB", flag_emoji: "🇺🇿", confederation: :afc }
].freeze

WC2026_NEW_TEAMS.each do |attrs|
  Team.find_or_create_by!(fifa_code: attrs[:fifa_code]) do |t|
    t.name          = attrs[:name]
    t.country_code  = attrs[:country_code]
    t.flag_emoji    = attrs[:flag_emoji]
    t.confederation = attrs[:confederation]
  end
end

# Link Zaire → DR Congo (Zaire renamed in 1997). Preserves historical
# match attribution while letting modern data attach to the COD row.
if (zaire = Team.find_by(fifa_code: "ZAI")) && (cod = Team.find_by(fifa_code: "COD"))
  zaire.update!(successor_team: cod) if zaire.successor_team_id.nil?
end

# --- Stadiums (15 new) -----------------------------------------------------

WC2026_STADIUMS = [
  { name: "MetLife Stadium",         city: "East Rutherford", country: "United States", country_code: "USA" },
  { name: "AT&T Stadium",            city: "Arlington",       country: "United States", country_code: "USA" },
  { name: "SoFi Stadium",            city: "Inglewood",       country: "United States", country_code: "USA" },
  { name: "Arrowhead Stadium",       city: "Kansas City",     country: "United States", country_code: "USA" },
  { name: "Levi's Stadium",          city: "Santa Clara",     country: "United States", country_code: "USA" },
  { name: "NRG Stadium",             city: "Houston",         country: "United States", country_code: "USA" },
  { name: "Mercedes-Benz Stadium",   city: "Atlanta",         country: "United States", country_code: "USA" },
  { name: "Lincoln Financial Field", city: "Philadelphia",    country: "United States", country_code: "USA" },
  { name: "Lumen Field",             city: "Seattle",         country: "United States", country_code: "USA" },
  { name: "Hard Rock Stadium",       city: "Miami Gardens",   country: "United States", country_code: "USA" },
  { name: "Gillette Stadium",        city: "Foxborough",      country: "United States", country_code: "USA" },
  { name: "BC Place",                city: "Vancouver",       country: "Canada",        country_code: "CAN" },
  { name: "BMO Field",               city: "Toronto",         country: "Canada",        country_code: "CAN" },
  { name: "Estadio BBVA",            city: "Monterrey",       country: "Mexico",        country_code: "MEX" },
  { name: "Estadio Akron",           city: "Guadalajara",     country: "Mexico",        country_code: "MEX" }
].freeze

WC2026_STADIUMS.each do |attrs|
  Stadium.find_or_create_by!(name: attrs[:name]) do |s|
    s.city         = attrs[:city]
    s.country      = attrs[:country]
    s.country_code = attrs[:country_code]
  end
end

# --- Tournament -----------------------------------------------------------

tournament = Tournament.find_or_create_by!(year: 2026) do |t|
  t.name           = "FIFA World Cup 2026"
  t.host_countries = ["Canada", "Mexico", "United States"]
  t.start_date     = Date.new(2026, 6, 11)
  t.end_date       = Date.new(2026, 7, 19)
  t.total_matches  = 104
  t.total_goals    = nil  # tournament hasn't started
end

# --- Fixtures (72 scheduled group-stage matches) --------------------------

team_by_code    = Team.where(fifa_code: GROUPS.values.flatten.uniq).index_by(&:fifa_code)
stadium_by_name = Stadium.where(name: WC2026_STADIUMS.map { |s| s[:name] } + ["Estadio Azteca"])
                          .index_by(&:name)

missing_teams = GROUPS.values.flatten.uniq - team_by_code.keys
abort("Missing teams in DB: #{missing_teams.inspect}") if missing_teams.any?

missing_stadiums = FIXTURES.map { |f| f["stadium"] }.uniq - stadium_by_name.keys
abort("Missing stadiums in DB: #{missing_stadiums.inspect}") if missing_stadiums.any?

created = 0
skipped = 0

FIXTURES.each do |f|
  home = team_by_code.fetch(f["home"])
  away = team_by_code.fetch(f["away"])

  match = Match.find_or_initialize_by(
    tournament_id: tournament.id,
    home_team_id:  home.id,
    away_team_id:  away.id,
    date:          f["date"]
  )

  if match.persisted?
    skipped += 1
    next
  end

  match.assign_attributes(
    stage:           :group_stage,
    result_type:     :scheduled,
    group_letter:    f["group"],
    stadium:         stadium_by_name.fetch(f["stadium"]),
    home_score:      0,
    away_score:      0,
    data_confidence: :verified
  )
  match.save!
  created += 1
end

puts "WC2026 seed: #{tournament.persisted? ? "tournament ✓" : "tournament X"}, " \
     "#{created} fixtures created, #{skipped} already present."
