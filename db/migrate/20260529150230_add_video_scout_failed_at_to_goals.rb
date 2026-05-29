class AddVideoScoutFailedAtToGoals < ActiveRecord::Migration[8.1]
  def change
    add_column :goals, :video_scout_failed_at, :datetime
  end
end
