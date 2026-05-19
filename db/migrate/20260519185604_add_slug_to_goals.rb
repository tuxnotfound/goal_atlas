class AddSlugToGoals < ActiveRecord::Migration[8.1]
  def up
    add_column :goals, :slug, :string

    Goal.reset_column_information
    Goal.includes(:player, match: [:home_team, :away_team, :tournament]).find_each do |goal|
      opponent_id = goal.scoring_team_id == goal.match.home_team_id ? goal.match.away_team_id : goal.match.home_team_id
      opponent = Team.find(opponent_id)
      year = goal.match.tournament.year
      goal.update_columns(slug: "#{goal.player.slug}-vs-#{opponent.slug}-#{year}-#{goal.minute}")
    end

    add_index :goals, :slug, unique: true
    change_column_null :goals, :slug, false
  end

  def down
    remove_index :goals, :slug
    remove_column :goals, :slug
  end
end
