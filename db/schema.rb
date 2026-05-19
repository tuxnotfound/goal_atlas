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

ActiveRecord::Schema[8.1].define(version: 2026_05_19_153001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  add_foreign_key "teams", "teams", column: "successor_team_id"
end
