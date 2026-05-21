class CreatePlayerImageTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :player_image_taggings do |t|
      t.references :player_image, null: false, foreign_key: true
      t.references :tournament, null: false, foreign_key: true

      t.timestamps
    end

    add_index :player_image_taggings, [:player_image_id, :tournament_id],
              unique: true, name: "index_player_image_taggings_unique"
  end
end
