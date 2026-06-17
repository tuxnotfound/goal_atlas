# Marks when Wc2026Sync has pulled a finished match's lineups and recorded
# tournament participations for the players who appeared. Lets the 15-minute
# sync skip fixtures it has already processed instead of re-fetching every
# lineup on every run.
class AddLineupsSyncedAtToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :lineups_synced_at, :datetime
  end
end
