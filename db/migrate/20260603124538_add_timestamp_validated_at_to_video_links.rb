class AddTimestampValidatedAtToVideoLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :video_links, :timestamp_validated_at, :datetime
  end
end
