class CreateTournamentAwards < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_awards do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :player,     null: false, foreign_key: true
      t.integer :award_type, null: false
      t.text :notes

      t.timestamps
    end

    add_index :tournament_awards, [:tournament_id, :award_type, :player_id],
              unique: true, name: "index_tournament_awards_uniq"
    add_index :tournament_awards, :award_type
  end
end
