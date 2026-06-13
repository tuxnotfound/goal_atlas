class AddApiFootballPlayerIdToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :api_football_player_id, :integer
    add_index  :players, :api_football_player_id, unique: true, where: "api_football_player_id IS NOT NULL"
  end
end
