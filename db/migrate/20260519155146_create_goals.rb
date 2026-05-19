class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :match, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :scoring_team, null: false, foreign_key: { to_table: :teams }
      t.integer :minute, null: false
      t.integer :stoppage_time
      t.integer :period, null: false
      t.integer :goal_order, null: false, default: 0
      t.integer :goal_type, null: false, default: 0
      t.integer :body_part
      t.references :assist_player, foreign_key: { to_table: :players }
      t.integer :score_after_goal_home, null: false
      t.integer :score_after_goal_away, null: false
      t.text :description
      t.integer :data_confidence, null: false, default: 1
      t.text :source_notes
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :goals, [:match_id, :period, :minute, :stoppage_time, :goal_order],
              name: "index_goals_on_match_and_sort_keys"
    add_index :goals, :goal_type
    add_index :goals, :discarded_at
  end
end
