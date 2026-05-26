class AddIsPortraitToPlayerImages < ActiveRecord::Migration[8.1]
  def change
    add_column :player_images, :is_portrait, :boolean, default: false, null: false
    add_index :player_images, [:player_id, :is_portrait],
              unique: true, where: "is_portrait = true",
              name: "index_player_images_one_portrait_per_player"
  end
end
