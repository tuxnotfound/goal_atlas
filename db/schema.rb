# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_19_155418) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "goals", force: :cascade do |t|
    t.bigint "assist_player_id"
    t.integer "body_part"
    t.datetime "created_at", null: false
    t.integer "data_confidence", default: 1, null: false
    t.text "description"
    t.datetime "discarded_at"
    t.integer "goal_order", default: 0, null: false
    t.integer "goal_type", default: 0, null: false
    t.bigint "match_id", null: false
    t.integer "minute", null: false
    t.integer "period", null: false
    t.bigint "player_id", null: false
    t.integer "score_after_goal_away", null: false
    t.integer "score_after_goal_home", null: false
    t.bigint "scoring_team_id", null: false
    t.text "source_notes"
    t.integer "stoppage_time"
    t.datetime "updated_at", null: false
    t.index ["assist_player_id"], name: "index_goals_on_assist_player_id"
    t.index ["discarded_at"], name: "index_goals_on_discarded_at"
    t.index ["goal_type"], name: "index_goals_on_goal_type"
    t.index ["match_id", "period", "minute", "stoppage_time", "goal_order"], name: "index_goals_on_match_and_sort_keys"
    t.index ["match_id"], name: "index_goals_on_match_id"
    t.index ["player_id"], name: "index_goals_on_player_id"
    t.index ["scoring_team_id"], name: "index_goals_on_scoring_team_id"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "attendance"
    t.integer "away_penalties"
    t.integer "away_score", default: 0, null: false
    t.integer "away_score_after_extra_time"
    t.bigint "away_team_id", null: false
    t.datetime "created_at", null: false
    t.integer "data_confidence", default: 1, null: false
    t.date "date", null: false
    t.datetime "discarded_at"
    t.string "group_letter"
    t.integer "home_penalties"
    t.integer "home_score", default: 0, null: false
    t.integer "home_score_after_extra_time"
    t.bigint "home_team_id", null: false
    t.integer "match_number"
    t.string "referee"
    t.integer "result_type", default: 0, null: false
    t.string "round_label"
    t.string "slug", null: false
    t.text "source_notes"
    t.bigint "stadium_id"
    t.integer "stage", null: false
    t.bigint "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "winner_team_id"
    t.index ["away_team_id"], name: "index_matches_on_away_team_id"
    t.index ["date"], name: "index_matches_on_date"
    t.index ["discarded_at"], name: "index_matches_on_discarded_at"
    t.index ["home_team_id"], name: "index_matches_on_home_team_id"
    t.index ["slug"], name: "index_matches_on_slug", unique: true
    t.index ["stadium_id"], name: "index_matches_on_stadium_id"
    t.index ["stage"], name: "index_matches_on_stage"
    t.index ["tournament_id", "match_number"], name: "index_matches_on_tournament_id_and_match_number"
    t.index ["tournament_id"], name: "index_matches_on_tournament_id"
    t.index ["winner_team_id"], name: "index_matches_on_winner_team_id"
    t.check_constraint "home_team_id <> away_team_id", name: "matches_distinct_teams"
  end

  create_table "players", force: :cascade do |t|
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.string "name_local"
    t.bigint "nationality_team_id"
    t.integer "position"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_players_on_discarded_at"
    t.index ["name"], name: "index_players_on_name"
    t.index ["nationality_team_id"], name: "index_players_on_nationality_team_id"
    t.index ["slug"], name: "index_players_on_slug", unique: true
  end

  create_table "shootout_kicks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "kick_order", null: false
    t.bigint "match_id", null: false
    t.string "notes"
    t.bigint "player_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "was_scored", null: false
    t.index ["discarded_at"], name: "index_shootout_kicks_on_discarded_at"
    t.index ["match_id", "kick_order"], name: "index_shootout_kicks_unique_order_per_match", unique: true
    t.index ["match_id"], name: "index_shootout_kicks_on_match_id"
    t.index ["player_id"], name: "index_shootout_kicks_on_player_id"
    t.index ["team_id"], name: "index_shootout_kicks_on_team_id"
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.text "notes"
    t.integer "reliability", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["discarded_at"], name: "index_sources_on_discarded_at"
    t.index ["name"], name: "index_sources_on_name", unique: true
  end

  create_table "stadiums", force: :cascade do |t|
    t.string "city", null: false
    t.string "country", null: false
    t.string "country_code"
    t.datetime "created_at", null: false
    t.integer "current_capacity"
    t.datetime "discarded_at"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.string "name", null: false
    t.text "notes"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_stadiums_on_city"
    t.index ["country_code"], name: "index_stadiums_on_country_code"
    t.index ["discarded_at"], name: "index_stadiums_on_discarded_at"
    t.index ["name"], name: "index_stadiums_on_name"
    t.index ["slug"], name: "index_stadiums_on_slug", unique: true
  end

  create_table "teams", force: :cascade do |t|
    t.integer "active_from"
    t.integer "active_until"
    t.integer "confederation", null: false
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "fifa_code"
    t.string "flag_emoji"
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "successor_team_id"
    t.datetime "updated_at", null: false
    t.index ["country_code"], name: "index_teams_on_country_code"
    t.index ["discarded_at"], name: "index_teams_on_discarded_at"
    t.index ["name"], name: "index_teams_on_name"
    t.index ["slug"], name: "index_teams_on_slug", unique: true
    t.index ["successor_team_id"], name: "index_teams_on_successor_team_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.date "end_date"
    t.bigint "fourth_place_team_id"
    t.string "host_countries", default: [], null: false, array: true
    t.string "name", null: false
    t.string "poster_url"
    t.bigint "runner_up_team_id"
    t.string "slug", null: false
    t.date "start_date"
    t.bigint "third_place_team_id"
    t.integer "total_goals"
    t.integer "total_matches"
    t.datetime "updated_at", null: false
    t.bigint "winner_team_id"
    t.integer "year", null: false
    t.index ["discarded_at"], name: "index_tournaments_on_discarded_at"
    t.index ["fourth_place_team_id"], name: "index_tournaments_on_fourth_place_team_id"
    t.index ["runner_up_team_id"], name: "index_tournaments_on_runner_up_team_id"
    t.index ["slug"], name: "index_tournaments_on_slug", unique: true
    t.index ["third_place_team_id"], name: "index_tournaments_on_third_place_team_id"
    t.index ["winner_team_id"], name: "index_tournaments_on_winner_team_id"
    t.index ["year"], name: "index_tournaments_on_year", unique: true
  end

  add_foreign_key "goals", "matches"
  add_foreign_key "goals", "players"
  add_foreign_key "goals", "players", column: "assist_player_id"
  add_foreign_key "goals", "teams", column: "scoring_team_id"
  add_foreign_key "matches", "stadiums"
  add_foreign_key "matches", "teams", column: "away_team_id"
  add_foreign_key "matches", "teams", column: "home_team_id"
  add_foreign_key "matches", "teams", column: "winner_team_id"
  add_foreign_key "matches", "tournaments"
  add_foreign_key "players", "teams", column: "nationality_team_id"
  add_foreign_key "shootout_kicks", "matches"
  add_foreign_key "shootout_kicks", "players"
  add_foreign_key "shootout_kicks", "teams"
  add_foreign_key "teams", "teams", column: "successor_team_id"
  add_foreign_key "tournaments", "teams", column: "fourth_place_team_id"
  add_foreign_key "tournaments", "teams", column: "runner_up_team_id"
  add_foreign_key "tournaments", "teams", column: "third_place_team_id"
  add_foreign_key "tournaments", "teams", column: "winner_team_id"
end
