require 'rails_helper'

RSpec.describe "Players", type: :request do
  describe "GET /players/:slug" do
    let!(:argentina) { create(:team, name: "Argentina") }
    let!(:messi)     { create(:player, :messi, nationality_team: argentina) }

    it "renders the player page" do
      get player_path(messi)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lionel Messi")
    end

    it "shows the player's nationality team linked" do
      get player_path(messi)
      expect(response.body).to include(team_path(argentina))
      expect(response.body).to include("Argentina")
    end

    it "lists the player's goals" do
      france  = create(:team, name: "France")
      tournament = create(:tournament, :wc_2022)
      stadium = create(:stadium, :lusail)
      match = create(:match,
                     tournament: tournament, stadium: stadium,
                     home_team: argentina, away_team: france,
                     stage: :final, date: Date.new(2022, 12, 18))
      create(:goal,
             match: match, player: messi, scoring_team: argentina,
             minute: 23, period: :first_half, goal_type: :penalty,
             score_after_goal_home: 1, score_after_goal_away: 0)

      get player_path(messi)
      expect(response.body).to include("Goals scored by Lionel Messi")
    end

    it "shows an empty state when the player has no goals" do
      get player_path(messi)
      expect(response.body).to include("No goals in our dataset yet")
    end

    it "404s for unknown slug" do
      get "/players/no-such-player"
      expect(response).to have_http_status(:not_found)
    end

    it "excludes discarded players" do
      messi.discard
      get player_path(messi)
      expect(response).to have_http_status(:not_found)
    end
  end
end
