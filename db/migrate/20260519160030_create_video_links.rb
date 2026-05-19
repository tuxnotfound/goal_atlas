class CreateVideoLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :video_links do |t|
      t.references :linkable, polymorphic: true, null: false
      t.integer :source, null: false
      t.string :url, null: false
      t.integer :starts_at_seconds
      t.integer :ends_at_seconds
      t.boolean :embed_allowed, null: false, default: false
      t.string :language
      t.integer :confidence, null: false, default: 1
      t.datetime :last_checked_at
      t.boolean :is_active, null: false, default: true
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :video_links, :source
    add_index :video_links, :is_active
    add_index :video_links, :discarded_at
  end
end
