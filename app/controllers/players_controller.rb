class PlayersController < ApplicationController
  def show
    @player = Player.kept.friendly.find(params[:slug])

    @goals = Goal.kept.by_player(@player)
                 .includes(:scoring_team, match: [:home_team, :away_team, :tournament])
                 .order("matches.date DESC, goals.minute ASC")
                 .references(:match)

    @tournament_records = PlayerTournamentRecord.for_player(@player)

    @shootout_totals = {
      taken:  @player.shootout_kicks.kept.count,
      scored: @player.shootout_kicks.kept.where(was_scored: true).count
    }
  end
end
