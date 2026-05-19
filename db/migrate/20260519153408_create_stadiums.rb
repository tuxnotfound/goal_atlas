class CreateStadiums < ActiveRecord::Migration[8.1]
  def change
    create_table :stadiums do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :city, null: false
      t.string :country, null: false
      t.string :country_code
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.integer :current_capacity
      t.text :notes
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :stadiums, :slug, unique: true
    add_index :stadiums, :name
    add_index :stadiums, :city
    add_index :stadiums, :country_code
    add_index :stadiums, :discarded_at
  end
end
