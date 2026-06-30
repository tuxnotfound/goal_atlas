require 'rails_helper'

RSpec.describe "Matches", type: :request do
  describe "GET /matches" do
    it "renders the match list" do
      create(:match, :final_2022)

      get matches_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Argentina")
      expect(response.body).to include("France")
      expect(response.body).to include("All matches").or include("Matches")
    end

    it "renders successfully when there are no matches" do
      get matches_path
      expect(response).to have_http_status(:ok)
    end

    it "shows only already-played matches, excluding scheduled/TBD placeholders" do
      create(:match, :final_2022) # played
      create(:match, # scheduled TBD knockout placeholder (nil teams)
             stage: :round_of_16, result_type: :scheduled, match_number: 89,
             group_letter: nil, date: Date.new(2026, 7, 4),
             home_team: nil, away_team: nil,
             home_source_label: "W74", away_source_label: "W77")

      get matches_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Argentina")          # played match shown
      expect(response.body).not_to include("Winner Match 74") # placeholder hidden
    end
  end

  describe "GET /matches/:slug for a TBD knockout placeholder" do
    it "renders the fixture without error, showing source labels" do
      match = create(:match,
                     stage: :round_of_16, result_type: :scheduled, match_number: 89,
                     group_letter: nil, date: Date.new(2026, 7, 4),
                     stadium: create(:stadium),
                     home_team: nil, away_team: nil,
                     home_source_label: "W74", away_source_label: "W77")

      get match_path(match)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Winner Match 74")
      expect(response.body).to include("Winner Match 77")
    end
  end

  describe "GET /matches/:slug" do
    let(:match) { create(:match, :final_2022) }

    it "renders the match show page" do
      get match_path(match)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(match.home_team.name)
      expect(response.body).to include(match.away_team.name)
    end

    it "renders the goal timeline" do
      messi = create(:player, :messi, nationality_team: match.home_team)
      create(:goal,
             match: match, player: messi, scoring_team: match.home_team,
             minute: 23, period: :first_half, goal_type: :penalty,
             score_after_goal_home: 1, score_after_goal_away: 0)

      get match_path(match)
      expect(response.body).to include("Lionel Messi")
      expect(response.body).to include("Penalty")
      expect(response.body).to include("23") # "23'" rendered with apostrophe escaped
    end

    it "renders video links when present" do
      match.video_links.create!(
        source: :fifa_plus, url: "https://www.fifa.com/fifaplus/match-highlight",
        confidence: :verified, is_active: true
      )

      get match_path(match)
      expect(response.body).to include("Watch")
      expect(response.body).to include("FIFA+")
      expect(response.body).to include("https://www.fifa.com/fifaplus/match-highlight")
    end

    it "renders the shootout when one exists" do
      create(:shootout_kick,
             match: match, team: match.home_team, kick_order: 1, was_scored: true)
      create(:shootout_kick,
             match: match, team: match.away_team, kick_order: 2, was_scored: false,
             notes: "saved by Emiliano Martínez")

      get match_path(match)
      expect(response.body).to include("Penalty shootout")
      expect(response.body).to include("saved by Emiliano Martínez")
    end

    it "404s for an unknown slug" do
      get "/matches/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end

    it "excludes discarded matches" do
      match.discard
      get match_path(match)
      expect(response).to have_http_status(:not_found)
    end
  end
end
