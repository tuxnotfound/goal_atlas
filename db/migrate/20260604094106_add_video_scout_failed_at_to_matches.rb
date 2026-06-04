class AddVideoScoutFailedAtToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :video_scout_failed_at, :datetime
  end
end
