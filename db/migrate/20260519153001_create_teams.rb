class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :country_code, null: false
      t.string :fifa_code
      t.string :flag_emoji
      t.integer :confederation, null: false
      t.integer :active_from
      t.integer :active_until
      t.references :successor_team, foreign_key: { to_table: :teams }
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :teams, :slug, unique: true
    add_index :teams, :name
    add_index :teams, :country_code
    add_index :teams, :discarded_at
  end
end
