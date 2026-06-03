class AddVideoDurationSecondsToVideoLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :video_links, :video_duration_seconds, :integer
  end
end
