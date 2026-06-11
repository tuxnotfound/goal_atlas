class SitemapsController < ApplicationController
  def show
    @tournaments = Tournament.kept.order(year: :asc)
    @matches     = Match.kept.order(:date, :match_number)
    @goals       = Goal.kept.order(:id)
    @players     = Player.kept.order(:name)
    @teams       = Team.kept.order(:name)

    expires_in 1.hour, public: true
    render layout: false
  end
end
