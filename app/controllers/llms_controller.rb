class LlmsController < ApplicationController
  def show
    @tournaments = Tournament.kept.order(year: :desc)
    @match_count = Match.kept.count
    @goal_count = Goal.kept.count
    @player_count = Player.kept.count

    expires_in 1.day, public: true
    render layout: false
  end
end
