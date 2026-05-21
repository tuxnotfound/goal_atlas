class EnablePgTrgm < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"

    add_index :teams,       :name, using: :gin, opclass: :gin_trgm_ops, name: "index_teams_on_name_trgm"
    add_index :players,     :name, using: :gin, opclass: :gin_trgm_ops, name: "index_players_on_name_trgm"
    add_index :tournaments, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_tournaments_on_name_trgm"
    add_index :stadiums,    :name, using: :gin, opclass: :gin_trgm_ops, name: "index_stadiums_on_name_trgm"
  end
end

