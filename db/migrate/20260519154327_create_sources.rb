class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :url
      t.integer :reliability, null: false
      t.text :notes
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :sources, :name, unique: true
    add_index :sources, :discarded_at
  end
end
