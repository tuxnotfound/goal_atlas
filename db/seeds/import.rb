# Imports players, matches, and goals for 1986/2018/2022 from vendored
# jfjelstul/worldcup CSV snapshots (db/data/jfjelstul/).
#
# Depends on: tournaments.rb, teams.rb, stadiums.rb
#
# Idempotent: matches keyed on (tournament, match_number); goals keyed on
# (match, scoring_team, player, minute, stoppage_time).

require "csv"

DATA_DIR = Rails.root.join("db", "data", "jfjelstul").freeze
YEARS = (1930..2022).step(4).to_a.reject { |y| y.between?(1942, 1946) }.freeze
TOURNAMENT_IDS = YEARS.map { |y| "WC-#{y}" }.to_set.freeze

# Maps jfjelstul team_id (T-XX) → our Team.fifa_code.
# Built once from teams.csv but kept explicit for traceability.
TEAM_ID_TO_FIFA = {
  "T-01" => "ALG", "T-02" => "ANG", "T-03" => "ARG", "T-04" => "AUS",
  "T-05" => "AUT", "T-06" => "BEL", "T-07" => "BOL", "T-08" => "BIH",
  "T-09" => "BRA", "T-10" => "BUL", "T-11" => "CMR", "T-12" => "CAN",
  "T-13" => "CHI", "T-14" => "CHN", "T-16" => "COL", "T-17" => "CRC",
  "T-18" => "CRO", "T-19" => "CUB", "T-20" => "CZE", "T-21" => "TCH",
  "T-22" => "DEN", "T-23" => "DEI", "T-24" => "GDR", "T-25" => "ECU",
  "T-26" => "EGY", "T-27" => "SLV", "T-28" => "ENG", "T-30" => "FRA",
  "T-31" => "GER", "T-32" => "GHA", "T-33" => "GRE", "T-34" => "HAI",
  "T-35" => "HON", "T-36" => "HUN", "T-37" => "ISL", "T-38" => "IRN",
  "T-39" => "IRQ", "T-40" => "ISR", "T-41" => "ITA", "T-42" => "CIV",
  "T-43" => "JAM", "T-44" => "JPN", "T-45" => "KUW", "T-46" => "MEX",
  "T-47" => "MAR", "T-48" => "NED", "T-49" => "NZL", "T-50" => "NGA",
  "T-51" => "PRK", "T-52" => "NIR", "T-53" => "NOR", "T-54" => "PAN",
  "T-55" => "PAR", "T-56" => "PER", "T-57" => "POL", "T-58" => "POR",
  "T-59" => "QAT", "T-60" => "IRL", "T-61" => "ROU", "T-62" => "RUS",
  "T-63" => "KSA", "T-64" => "SCO", "T-65" => "SEN", "T-66" => "SRB",
  "T-67" => "SCG", "T-68" => "SVK", "T-69" => "SVN", "T-70" => "RSA",
  "T-71" => "KOR", "T-72" => "URS", "T-73" => "ESP", "T-74" => "SWE",
  "T-75" => "SUI", "T-77" => "TGO", "T-78" => "TRI", "T-79" => "TUN",
  "T-80" => "TUR", "T-81" => "UKR", "T-82" => "UAE", "T-83" => "USA",
  "T-84" => "URU", "T-85" => "WAL", "T-86" => "FRG", "T-87" => "YUG",
  "T-88" => "ZAI"
}.freeze

# jfjelstul stadium name → our seeded stadium name (when they differ).
STADIUM_NAME_ALIASES = {
  "Estadio Sergio León Chavez"   => "Estadio Sergio León Chávez",
  "Estadio Universitario"        => "Estadio Universitario (Monterrey)",
  "Estadio La Corregidora"       => "Estadio Corregidora",
  "La Bombonera"                 => "Estadio Nemesio Díez", # Toluca, MX (Bombonera nickname)
  "Otkritie Arena"               => "Otkrytie Arena",
  "Krestovsky Stadium"           => "Saint Petersburg Stadium",
  "Central Stadium"              => "Ekaterinburg Arena",
  "Lusail Stadium"               => "Lusail Iconic Stadium"
}.freeze

STAGE_MAP = {
  "group stage"        => :group_stage,
  "second group stage" => :second_group_stage,
  "final round"        => :second_group_stage, # 1950's unique round-robin "final pool"
  "round of 16"        => :round_of_16,
  "quarter-finals"     => :quarter_final,
  "quarter-final"      => :quarter_final,
  "semi-finals"        => :semi_final,
  "semi-final"         => :semi_final,
  "third-place match"  => :third_place_playoff,
  "final"              => :final
}.freeze

PERIOD_MAP = {
  "first half"                          => :first_half,
  "first half, stoppage time"           => :first_half,
  "second half"                         => :second_half,
  "second half, stoppage time"          => :second_half,
  "extra time, first half"              => :extra_time_first,
  "extra time, first half, stoppage time" => :extra_time_first,
  "extra time, second half"             => :extra_time_second,
  "extra time, second half, stoppage time" => :extra_time_second
}.freeze

POSITION_PRIORITY = %i[goalkeeper defender midfielder forward].freeze

def jf_csv(name)
  CSV.read(DATA_DIR.join("#{name}.csv"), headers: true)
end

def player_full_name(given, family)
  given = nil if given.blank? || given.strip.casecmp("not applicable").zero?
  family = family.to_s.strip
  return family if given.nil?
  "#{given.strip} #{family}".strip
end

def lookup_team(team_id)
  code = TEAM_ID_TO_FIFA[team_id] or raise "Unknown jfjelstul team_id: #{team_id}"
  Team.find_by!(fifa_code: code)
end

def lookup_stadium(name, city: nil, country: nil)
  return nil if name.blank?
  canonical = STADIUM_NAME_ALIASES.fetch(name, name)
  Stadium.find_by(name: canonical) || Stadium.create!(
    name:         canonical,
    city:         city,
    country:      country,
    country_code: nil
  )
end

def parse_match_number(match_id)
  match_id.to_s.split("-").last.to_i
end

def parse_position(row)
  POSITION_PRIORITY.find { |pos| row[pos.to_s] == "1" }
end

# ---------------------------------------------------------------------------
# Players
# ---------------------------------------------------------------------------
# We import only players who appear in our 3 tournaments' goals or shootouts,
# so each imported player has a known nationality (from those rows).

players_raw = jf_csv("players").to_h { |r| [r["player_id"], r] }
goals_csv   = jf_csv("goals").select   { |r| TOURNAMENT_IDS.include?(r["tournament_id"]) }
pks_csv     = jf_csv("penalty_kicks").select { |r| TOURNAMENT_IDS.include?(r["tournament_id"]) }
awards_csv  = jf_csv("award_winners").select { |r| TOURNAMENT_IDS.include?(r["tournament_id"]) }

player_ids_we_need = (
  goals_csv.map  { |r| r["player_id"] } +
  pks_csv.map    { |r| r["player_id"] } +
  awards_csv.map { |r| r["player_id"] }
).uniq

player_nationality = {} # player_id → team_id
goals_csv.each  { |r| player_nationality[r["player_id"]] ||= r["player_team_id"] }
pks_csv.each    { |r| player_nationality[r["player_id"]] ||= r["team_id"] }
awards_csv.each { |r| player_nationality[r["player_id"]] ||= r["team_id"] if r["team_id"].present? }

players_created = 0
player_ids_we_need.each do |pid|
  meta = players_raw[pid] or next
  name = player_full_name(meta["given_name"], meta["family_name"])
  nat_team_id = player_nationality[pid]

  player = Player.find_or_initialize_by(name: name)
  player.nationality_team ||= lookup_team(nat_team_id) if nat_team_id.present?
  player.position         ||= parse_position(meta)
  bd = meta["birth_date"]
  if bd.present? && bd != "not applicable"
    player.birth_date ||= (Date.parse(bd) rescue nil)
  end

  if player.new_record? || player.changed?
    player.save!
    players_created += 1 if player.previously_new_record?
  end
end
puts "Players: #{Player.count} (imported batch added #{players_created})"

# ---------------------------------------------------------------------------
# Matches
# ---------------------------------------------------------------------------

matches_csv = jf_csv("matches").select { |r| TOURNAMENT_IDS.include?(r["tournament_id"]) }
matches_created = 0

# Pre-compute 90' (regulation) score per match from goals.csv. jfjelstul's
# home_team_score column is the post-ET score; our schema separates them.
regulation_score = Hash.new { |h, k| h[k] = { home: 0, away: 0 } }
goals_csv.each do |g|
  next if g["match_period"].to_s.start_with?("extra time")
  bucket = regulation_score[g["match_id"]]
  if g["home_team"] == "1"
    bucket[:home] += 1
  else
    bucket[:away] += 1
  end
end

matches_csv.each do |row|
  tournament = Tournament.find_by!(year: row["tournament_id"].sub("WC-", "").to_i)
  home = lookup_team(row["home_team_id"])
  away = lookup_team(row["away_team_id"])
  stadium = lookup_stadium(row["stadium_name"], city: row["city_name"], country: row["country_name"])

  extra_time = row["extra_time"] == "1"
  shootout   = row["penalty_shootout"] == "1"
  full_home  = row["home_team_score"].to_i
  full_away  = row["away_team_score"].to_i

  reg = regulation_score[row["match_id"]]
  reg_home = extra_time ? reg[:home] : full_home
  reg_away = extra_time ? reg[:away] : full_away

  result_type =
    if shootout                then :after_penalties
    elsif extra_time           then :after_extra_time
    else                            :regulation
    end

  winner = case row["result"]
           when "home team win" then home
           when "away team win" then away
           end

  match = Match.find_or_initialize_by(tournament: tournament, match_number: parse_match_number(row["match_id"]))
  match.home_team    = home
  match.away_team    = away
  match.stadium      = stadium
  match.date         = Date.parse(row["match_date"])
  match.stage        = STAGE_MAP.fetch(row["stage_name"])
  match.group_letter = row["group_name"].to_s.sub(/^Group\s+/, "").presence&.then { |g| g unless g == "not applicable" }
  match.home_score   = reg_home
  match.away_score   = reg_away
  match.home_score_after_extra_time = full_home if extra_time
  match.away_score_after_extra_time = full_away if extra_time
  match.home_penalties = row["home_team_score_penalties"].to_i if shootout
  match.away_penalties = row["away_team_score_penalties"].to_i if shootout
  match.result_type  = result_type
  match.winner_team  = winner
  match.data_confidence = :verified

  if match.new_record? || match.changed?
    match.save!
    matches_created += 1 if match.previously_new_record?
  end
end
puts "Matches: #{Match.count} (imported batch added #{matches_created})"

# ---------------------------------------------------------------------------
# Goals
# ---------------------------------------------------------------------------
# Process per match so we can track running score for score_after_goal_* and
# assign goal_order for goals sharing the same minute.

goals_by_match = goals_csv.group_by { |r| r["match_id"] }
goals_created = 0

goals_by_match.each do |match_id, rows|
  year = match_id.split("-")[1].to_i
  number = parse_match_number(match_id)
  match = Match.find_by(tournament: Tournament.find_by!(year: year), match_number: number)
  next unless match

  # Sort by (period order, minute, stoppage) so running score is right.
  sorted = rows.sort_by do |g|
    period = PERIOD_MAP[g["match_period"]] || :second_half
    [
      Goal::PERIODS[period],
      g["minute_regulation"].to_i,
      g["minute_stoppage"].to_i
    ]
  end

  home_total = 0
  away_total = 0
  minute_counter = Hash.new(0)

  sorted.each do |row|
    scoring_team = lookup_team(row["team_id"])
    period = PERIOD_MAP.fetch(row["match_period"])

    name = player_full_name(row["given_name"], row["family_name"])
    player = Player.find_by(name: name)
    unless player
      # Defensive: every scorer should have been seeded above; skip and warn.
      warn "Goal skipped — player not found: #{name} in #{match_id}"
      next
    end

    if scoring_team.id == match.home_team_id
      home_total += 1
    else
      away_total += 1
    end

    minute = row["minute_regulation"].to_i
    stoppage = row["minute_stoppage"].to_i.then { |s| s.zero? ? nil : s }
    key = [period, minute, stoppage]
    order = minute_counter[key]
    minute_counter[key] += 1

    goal_type =
      if row["own_goal"] == "1"    then :own_goal
      elsif row["penalty"] == "1"  then :penalty
      else                              :open_play
      end

    goal = Goal.find_or_initialize_by(
      match: match,
      scoring_team: scoring_team,
      player: player,
      minute: minute,
      stoppage_time: stoppage,
      goal_order: order
    )
    goal.period                = period
    goal.goal_type             = goal_type
    goal.score_after_goal_home = home_total
    goal.score_after_goal_away = away_total
    goal.data_confidence       = :verified

    if goal.new_record? || goal.changed?
      goal.save!
      goals_created += 1 if goal.previously_new_record?
    end
  end
end
puts "Goals: #{Goal.count} (imported batch added #{goals_created})"

# ---------------------------------------------------------------------------
# Shootout kicks
# ---------------------------------------------------------------------------
# penalty_kicks.csv lists each shootout kick in order; we assign kick_order
# per match by row sequence within the match.

pks_by_match = pks_csv.group_by { |r| r["match_id"] }
kicks_created = 0

pks_by_match.each do |match_id, rows|
  year = match_id.split("-")[1].to_i
  match = Match.find_by(tournament: Tournament.find_by!(year: year), match_number: parse_match_number(match_id))
  next unless match

  # jfjelstul groups rows by team rather than by shooting order. Interleave
  # home/away to approximate the alternating sequence (first-kicker side is
  # not recorded; we default to home first).
  home_rows = rows.select { |r| r["home_team"] == "1" }
  away_rows = rows.select { |r| r["away_team"] == "1" }
  interleaved = [home_rows.size, away_rows.size].max.times.flat_map do |i|
    [home_rows[i], away_rows[i]].compact
  end

  interleaved.each_with_index do |row, idx|
    name = player_full_name(row["given_name"], row["family_name"])
    player = Player.find_by(name: name)
    unless player
      warn "Shootout kick skipped — player not found: #{name} in #{match_id}"
      next
    end

    kick = ShootoutKick.find_or_initialize_by(match: match, kick_order: idx + 1)
    kick.team       = lookup_team(row["team_id"])
    kick.player     = player
    kick.was_scored = row["converted"] == "1"

    if kick.new_record? || kick.changed?
      kick.save!
      kicks_created += 1 if kick.previously_new_record?
    end
  end
end
puts "ShootoutKicks: #{ShootoutKick.count} (imported batch added #{kicks_created})"
