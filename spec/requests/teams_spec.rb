require 'rails_helper'

RSpec.describe "Teams", type: :request do
  describe "GET /teams/:slug" do
    let!(:argentina) { create(:team, name: "Argentina") }
    let!(:france)    { create(:team, name: "France") }

    it "renders the team page" do
      get team_path(argentina)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Argentina")
    end

    it "shows goals scored by the team" do
      tournament = create(:tournament, :wc_2022)
      stadium = create(:stadium, :lusail)
      match = create(:match,
                     tournament: tournament, stadium: stadium,
                     home_team: argentina, away_team: france,
                     stage: :final, date: Date.new(2022, 12, 18),
                     home_score: 1, away_score: 0,
                     winner_team: argentina, result_type: :regulation)
      messi = create(:player, :messi, nationality_team: argentina)
      create(:goal,
             match: match, player: messi, scoring_team: argentina,
             minute: 23, period: :first_half, goal_type: :penalty,
             score_after_goal_home: 1, score_after_goal_away: 0)

      get team_path(argentina)
      expect(response.body).to include("Goals scored by Argentina")
      expect(response.body).to include("Lionel Messi")
    end

    it "shows matches the team played" do
      tournament = create(:tournament, :wc_2022)
      stadium = create(:stadium, :lusail)
      create(:match,
             tournament: tournament, stadium: stadium,
             home_team: argentina, away_team: france,
             stage: :final, date: Date.new(2022, 12, 18))

      get team_path(argentina)
      expect(response.body).to include("Matches")
      expect(response.body).to include("France")
    end

    it "404s for unknown slug" do
      get "/teams/no-such-team"
      expect(response).to have_http_status(:not_found)
    end

    it "excludes discarded teams" do
      argentina.discard
      get team_path(argentina)
      expect(response).to have_http_status(:not_found)
    end
  end
end
