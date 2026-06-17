class PlayersController < ApplicationController
  def show
    @player = Player.kept.friendly.find(params[:slug])

    # excluding_own_goals: an own goal is credited to the opponent, so it is
    # not part of this player's scoring record (and would otherwise inflate the
    # career "Goals" total, which is just @goals.size).
    @goals = Goal.kept.by_player(@player).excluding_own_goals
                 .includes(:scoring_team, :video_links, match: [:home_team, :away_team, :tournament])
                 .order("matches.date DESC, goals.minute ASC")
                 .references(:match)

    @tournament_records = PlayerTournamentRecord.for_player(@player)

    @shootout_totals = {
      taken:  @player.shootout_kicks.kept.count,
      scored: @player.shootout_kicks.kept.where(was_scored: true).count
    }
  end
end
