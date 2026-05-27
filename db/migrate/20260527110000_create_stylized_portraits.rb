class CreateStylizedPortraits < ActiveRecord::Migration[8.1]
  def change
    create_table :stylized_portraits do |t|
      t.references :player, null: false, foreign_key: true, index: true
      t.references :source_player_image, foreign_key: { to_table: :player_images }, null: true, index: true
      t.string     :file_path,    null: false
      t.boolean    :is_selected,  default: false, null: false
      t.string     :model
      t.string     :quality
      t.string     :size
      t.text       :prompt
      t.datetime   :generated_at, null: false
      t.timestamps
    end

    add_index :stylized_portraits, [:player_id, :is_selected],
              unique: true, where: "is_selected = true",
              name: "index_stylized_portraits_one_selected_per_player"
  end
end
