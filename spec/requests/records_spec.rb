require 'rails_helper'

RSpec.describe "Records", type: :request do
  describe "GET /records" do
    it "renders the all-time records page with each leaderboard heading" do
      get records_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("All-Time Records")
      expect(response.body).to include("Most goals")
      expect(response.body).to include("Most tournaments won")
      expect(response.body).to include("Most hat-tricks")
    end

    it "lists the all-time top scorer" do
      tournament = create(:tournament, year: 2014)
      brazil = create(:team, name: "Brazil", fifa_code: "BRA")
      france = create(:team, name: "France", fifa_code: "FRA")
      match  = create(:match, tournament: tournament, home_team: brazil, away_team: france)
      striker = create(:player, name: "Ronaldo Nazário", nationality_team: brazil)
      create(:goal, match: match, player: striker, scoring_team: brazil, minute: 10)
      create(:goal, match: match, player: striker, scoring_team: brazil, minute: 20)

      get records_path
      expect(response.body).to include("Ronaldo Nazário")
    end

    it "renders an empty-state when there is no data" do
      get records_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No data yet")
    end
  end
end
