class CreateGoalTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_taggings do |t|
      t.references :goal, null: false, foreign_key: true
      t.references :goal_tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :goal_taggings, [:goal_id, :goal_tag_id], unique: true, name: "index_goal_taggings_uniq"
  end
end
