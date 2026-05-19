class PlayersController < ApplicationController
  def show
    @player = Player.kept.friendly.find(params[:slug])

    @goals = Goal.kept.by_player(@player)
                 .includes(:scoring_team, match: [:home_team, :away_team, :tournament])
                 .order("matches.date ASC, goals.minute ASC")
                 .references(:match)
  end
end
