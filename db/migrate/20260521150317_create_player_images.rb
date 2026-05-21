class CreatePlayerImages < ActiveRecord::Migration[8.1]
  def change
    create_table :player_images do |t|
      t.references :player, null: false, foreign_key: true
      t.string :url, null: false
      t.string :source_url
      t.string :thumbnail_url
      t.string :license
      t.string :license_url
      t.string :author
      t.text :description
      t.boolean :is_default, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.datetime :fetched_at
      t.text :notes
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :player_images, :discarded_at
    add_index :player_images, [:player_id, :url], unique: true
    add_index :player_images, [:player_id, :is_default],
              unique: true, where: "is_default = true",
              name: "index_player_images_one_default_per_player"
  end
end
