# Records the per-kick penalty shootouts for WC2026 knockout matches, so the
# match page shows the kick-by-kick list like past tournaments (api-football
# gives only the aggregate score). Reads db/data/wc2026/shootouts.yml.
#
# Idempotent — keyed on (match, kick_order). Kickers are resolved by their
# api-football player id; any not yet in the DB are created under the kicking
# team. Re-runnable and safe to wire into db:seed.

require "yaml"

DATA_DIR  = Rails.root.join("db/data/wc2026") unless defined?(DATA_DIR)
SHOOTOUTS = YAML.load_file(DATA_DIR.join("shootouts.yml"))

tournament = Tournament.find_by!(year: 2026)
team_by_code = Team.where(fifa_code: SHOOTOUTS.flat_map { |s| s["kicks"].map { |k| k["team"] } }.uniq)
                   .index_by(&:fifa_code)

kicks_created = 0
players_created = 0

SHOOTOUTS.each do |shootout|
  match = Match.find_by(tournament: tournament, match_number: shootout["match_number"])

  # Skip until the match actually carries the two teams these kicks belong to —
  # on a fresh seed the knockout matches are still TBD placeholders, and we only
  # want to record a shootout once its real contestants are in place.
  shootout_team_ids = shootout["kicks"].map { |k| team_by_code.fetch(k["team"]).id }.uniq.sort
  next unless [match&.home_team_id, match&.away_team_id].compact.sort == shootout_team_ids

  shootout["kicks"].each_with_index do |k, idx|
    team = team_by_code.fetch(k["team"])

    player = Player.find_by(api_football_player_id: k["api"])
    unless player
      player = Player.create!(name: k["name"], nationality_team: team, api_football_player_id: k["api"])
      players_created += 1
    end

    kick = ShootoutKick.find_or_initialize_by(match: match, kick_order: idx + 1)
    kick.assign_attributes(team: team, player: player, was_scored: k["scored"])
    kicks_created += 1 if kick.new_record?
    kick.save!
  end
end

puts "WC2026 shootouts seed: #{kicks_created} kicks, #{players_created} players created."
