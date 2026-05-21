class EnrichPlayerImagesWithCommonsMetadata < ActiveRecord::Migration[8.1]
  def change
    add_column :player_images, :image_width,         :integer
    add_column :player_images, :image_height,        :integer
    add_column :player_images, :commons_categories,  :string, array: true, default: []
  end
end
