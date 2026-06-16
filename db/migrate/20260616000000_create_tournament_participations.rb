class CreateTournamentParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_participations do |t|
      # player_id is covered by the composite unique index below, so skip the
      # default single-column index to avoid redundancy.
      t.references :player,     null: false, foreign_key: true, index: false
      t.references :tournament, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tournament_participations, %i[player_id tournament_id],
              unique: true, name: "index_tournament_participations_uniq"
  end
end
