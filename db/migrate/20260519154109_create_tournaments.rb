class CreateTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :tournaments do |t|
      t.integer :year, null: false
      t.string :slug, null: false
      t.string :name, null: false
      t.string :host_countries, array: true, null: false, default: []
      t.date :start_date
      t.date :end_date
      t.references :winner_team,       foreign_key: { to_table: :teams }
      t.references :runner_up_team,    foreign_key: { to_table: :teams }
      t.references :third_place_team,  foreign_key: { to_table: :teams }
      t.references :fourth_place_team, foreign_key: { to_table: :teams }
      t.integer :total_matches
      t.integer :total_goals
      t.string :poster_url
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :tournaments, :year, unique: true
    add_index :tournaments, :slug, unique: true
    add_index :tournaments, :discarded_at
  end
end
