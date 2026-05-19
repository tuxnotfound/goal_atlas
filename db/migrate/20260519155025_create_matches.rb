class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :tournament, null: false, foreign_key: true
      t.integer :stage, null: false
      t.string :round_label
      t.string :group_letter
      t.integer :match_number
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }
      t.integer :home_score, null: false, default: 0
      t.integer :away_score, null: false, default: 0
      t.integer :home_score_after_extra_time
      t.integer :away_score_after_extra_time
      t.integer :home_penalties
      t.integer :away_penalties
      t.date :date, null: false
      t.references :stadium, foreign_key: true
      t.integer :attendance
      t.string :referee
      t.integer :result_type, null: false, default: 0
      t.references :winner_team, foreign_key: { to_table: :teams }
      t.integer :data_confidence, null: false, default: 1
      t.text :source_notes
      t.string :slug, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :matches, :slug, unique: true
    add_index :matches, :date
    add_index :matches, :stage
    add_index :matches, [:tournament_id, :match_number]
    add_index :matches, :discarded_at

    add_check_constraint :matches, "home_team_id <> away_team_id", name: "matches_distinct_teams"
  end
end
