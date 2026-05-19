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

ActiveRecord::Schema[8.1].define(version: 2026_05_19_154109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "teams", "teams", column: "successor_team_id"
  add_foreign_key "tournaments", "teams", column: "fourth_place_team_id"
  add_foreign_key "tournaments", "teams", column: "runner_up_team_id"
  add_foreign_key "tournaments", "teams", column: "third_place_team_id"
  add_foreign_key "tournaments", "teams", column: "winner_team_id"
end
