require 'rails_helper'

RSpec.describe "Tournaments", type: :request do
  describe "GET /world-cups" do
    it "renders the tournaments index" do
      create(:tournament, :wc_2022)
      create(:tournament, year: 2018, name: "FIFA World Cup 2018", host_countries: ["Russia"])

      get tournaments_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("World Cups")
      expect(response.body).to include("Qatar")
      expect(response.body).to include("Russia")
    end

    it "orders tournaments by year descending" do
      create(:tournament, year: 2018, name: "FIFA World Cup 2018", host_countries: ["Russia"])
      create(:tournament, :wc_2022)

      get tournaments_path
      idx_2022 = response.body.index("2022")
      idx_2018 = response.body.index("2018")
      expect(idx_2022).to be < idx_2018
    end

    it "renders an empty-state message when there are no tournaments" do
      get tournaments_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No tournaments in the archive yet")
    end

    it "is the application root" do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("World Cups")
    end
  end

  describe "GET /world-cups/:year" do
    let!(:argentina) { create(:team, name: "Argentina") }
    let!(:france)    { create(:team, name: "France") }
    let!(:croatia)   { create(:team, name: "Croatia") }
    let!(:morocco)   { create(:team, name: "Morocco") }
    let!(:stadium)   { create(:stadium, :lusail) }
    let!(:tournament) {
      create(:tournament, :wc_2022,
             winner_team: argentina, runner_up_team: france,
             third_place_team: croatia, fourth_place_team: morocco)
    }

    it "renders the tournament page at /world-cups/:year" do
      get "/world-cups/2022"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FIFA World Cup 2022")
    end

    it "uses /world-cups/2022 via path helper" do
      expect(tournament_path(tournament)).to eq("/world-cups/2022")
    end

    it "renders the final standings (podium)" do
      get tournament_path(tournament)
      expect(response.body).to include("Final standings")
      expect(response.body).to include("Argentina")
      expect(response.body).to include("France")
      expect(response.body).to include("Croatia")
      expect(response.body).to include("Morocco")
    end

    it "renders top scorers ordered by goal count" do
      messi  = create(:player, :messi, nationality_team: argentina)
      mbappe = create(:player, :mbappe, nationality_team: france)

      final = create(:match, :final_2022,
                     tournament: tournament, stadium: stadium,
                     home_team: argentina, away_team: france)

      # Messi: 2 goals, Mbappé: 1 goal — Messi should rank first.
      create(:goal, match: final, player: messi,  scoring_team: argentina,
             minute: 23,  period: :first_half,  score_after_goal_home: 1, score_after_goal_away: 0)
      create(:goal, match: final, player: messi,  scoring_team: argentina,
             minute: 108, period: :extra_time_first, score_after_goal_home: 3, score_after_goal_away: 2)
      create(:goal, match: final, player: mbappe, scoring_team: france,
             minute: 80,  period: :second_half, goal_type: :penalty,
             score_after_goal_home: 2, score_after_goal_away: 1)

      get tournament_path(tournament)
      expect(response.body).to include("Top scorers")
      expect(response.body).to include("Lionel Messi")
      expect(response.body).to include("Kylian Mbapp")
      messi_pos = response.body.index("Lionel Messi")
      mbappe_pos = response.body.index("Kylian Mbapp")
      expect(messi_pos).to be < mbappe_pos
    end

    it "groups matches by stage with the final on top" do
      final = create(:match, :final_2022,
                     tournament: tournament, stadium: stadium,
                     home_team: argentina, away_team: france)
      semi = create(:match,
                    tournament: tournament, stadium: stadium,
                    home_team: argentina, away_team: croatia,
                    stage: :semi_final, date: Date.new(2022, 12, 13),
                    home_score: 3, away_score: 0, result_type: :regulation,
                    winner_team: argentina)

      get tournament_path(tournament)

      # Stage headings are rendered as <h3>...Final...</h3> with whitespace inside.
      final_idx = response.body =~ %r{<h3[^>]*>\s*Final\s*</h3>}
      semi_idx  = response.body =~ %r{<h3[^>]*>\s*Semi final\s*</h3>}
      expect(final_idx).to be_present
      expect(semi_idx).to be_present
      expect(final_idx).to be < semi_idx
    end

    it "404s for an unknown year" do
      get "/world-cups/1999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
