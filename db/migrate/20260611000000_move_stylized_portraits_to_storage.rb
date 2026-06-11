class MoveStylizedPortraitsToStorage < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE stylized_portraits
      SET file_path = regexp_replace(file_path, '^public/stylized_portraits/', '')
      WHERE file_path LIKE 'public/stylized_portraits/%'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE stylized_portraits
      SET file_path = 'public/stylized_portraits/' || file_path
      WHERE file_path NOT LIKE 'public/stylized_portraits/%'
    SQL
  end
end
