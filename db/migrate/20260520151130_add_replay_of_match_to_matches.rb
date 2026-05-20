class AddReplayOfMatchToMatches < ActiveRecord::Migration[8.1]
  def change
    add_reference :matches, :replay_of_match, foreign_key: { to_table: :matches }
  end
end
