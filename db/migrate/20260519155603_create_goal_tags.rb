class CreateGoalTags < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :goal_tags, :name, unique: true
    add_index :goal_tags, :slug, unique: true
  end
end
