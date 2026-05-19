class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :name_local
      t.date :birth_date
      t.references :nationality_team, foreign_key: { to_table: :teams }
      t.integer :position
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :players, :slug, unique: true
    add_index :players, :name
    add_index :players, :discarded_at
  end
end
