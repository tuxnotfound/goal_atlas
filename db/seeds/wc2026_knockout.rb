# Seeds the 32 WC2026 knockout matches (73–104) as scheduled placeholders.
#
# Reads db/data/wc2026/knockout.yml. Teams are left nil until known — each side
# carries a source label ("1E", "3ABCDF", "W74", "L101", …) describing where it
# comes from. Real teams are filled in later by Wc2026BracketPopulator as group
# standings settle. Idempotent — keyed on (tournament, match_number).

require "yaml"

DATA_DIR = Rails.root.join("db/data/wc2026") unless defined?(DATA_DIR)
KNOCKOUT = YAML.load_file(DATA_DIR.join("knockout.yml"), permitted_classes: [Date])

tournament = Tournament.find_by!(year: 2026)

stadium_names   = KNOCKOUT.map { |k| k["stadium"] }.uniq
stadium_by_name = Stadium.where(name: stadium_names).index_by(&:name)

missing_stadiums = stadium_names - stadium_by_name.keys
abort("WC2026 knockout: missing stadiums in DB: #{missing_stadiums.inspect}") if missing_stadiums.any?

created = 0
skipped = 0

KNOCKOUT.each do |k|
  match = Match.find_or_initialize_by(tournament_id: tournament.id, match_number: k["match_number"])

  if match.persisted?
    skipped += 1
    next
  end

  match.assign_attributes(
    stage:             k["stage"],
    result_type:       :scheduled,
    date:              k["date"],
    stadium:           stadium_by_name.fetch(k["stadium"]),
    home_source_label: k["home"],
    away_source_label: k["away"],
    home_score:        0,
    away_score:        0,
    data_confidence:   :verified
  )
  match.save!
  created += 1
end

puts "WC2026 knockout seed: #{created} matches created, #{skipped} already present."
