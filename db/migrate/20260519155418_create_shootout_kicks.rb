class CreateShootoutKicks < ActiveRecord::Migration[8.1]
  def change
    create_table :shootout_kicks do |t|
      t.references :match, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :kick_order, null: false
      t.boolean :was_scored, null: false
      t.string :notes
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :shootout_kicks, [:match_id, :kick_order], unique: true, name: "index_shootout_kicks_unique_order_per_match"
    add_index :shootout_kicks, :discarded_at
  end
end
