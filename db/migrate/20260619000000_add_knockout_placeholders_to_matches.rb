# Lets knockout matches exist before their teams are known: nullable team FKs
# plus source-label columns describing where each side comes from
# ("2A" = runner-up group A, "1E" = winner group E, "3ABCDF" = best 3rd of that
# set, "W74" = winner of match 74, "L101" = loser of match 101). Used by the
# WC2026 placeholder bracket; historical matches keep both teams set.
class AddKnockoutPlaceholdersToMatches < ActiveRecord::Migration[8.1]
  def change
    change_column_null :matches, :home_team_id, true
    change_column_null :matches, :away_team_id, true

    add_column :matches, :home_source_label, :string
    add_column :matches, :away_source_label, :string
  end
end
