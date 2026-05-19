require 'rails_helper'

RSpec.describe "Goals", type: :request do
  describe "GET /goals/:slug" do
    let(:match) { create(:match, :final_2022) }
    let(:messi) { create(:player, :messi, nationality_team: match.home_team) }
    let!(:goal) do
      create(:goal,
             match: match, player: messi, scoring_team: match.home_team,
             minute: 23, period: :first_half, goal_type: :penalty, body_part: :left_foot,
             score_after_goal_home: 1, score_after_goal_away: 0)
    end

    it "renders the goal page" do
      get goal_path(goal)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(messi.name)
      expect(response.body).to include("Penalty")
    end

    it "links back to the match" do
      get goal_path(goal)
      expect(response.body).to include(match_path(match))
    end

    it "uses a friendly slug" do
      expect(goal.slug).to include("lionel-messi-vs-france")
    end

    it "404s for an unknown slug" do
      get "/goals/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end

    it "excludes discarded goals" do
      goal.discard
      get goal_path(goal)
      expect(response).to have_http_status(:not_found)
    end

    context "video links" do
      it "renders Watch buttons when active video links exist" do
        goal.video_links.create!(
          source: :youtube_official, url: "https://www.youtube.com/watch?v=abc123",
          confidence: :verified, embed_allowed: false, is_active: true
        )

        get goal_path(goal)
        expect(response.body).to include("Watch")
        expect(response.body).to include("YouTube")
        expect(response.body).to include("https://www.youtube.com/watch?v=abc123")
      end

      it "skips inactive and discarded video links" do
        goal.video_links.create!(source: :youtube_official, url: "https://www.youtube.com/watch?v=inactive", is_active: false)
        discarded = goal.video_links.create!(source: :youtube_official, url: "https://www.youtube.com/watch?v=gone")
        discarded.discard

        get goal_path(goal)
        expect(response.body).not_to include("v=inactive")
        expect(response.body).not_to include("v=gone")
      end

      it "appends ?t= to YouTube URLs when starts_at_seconds is set" do
        goal.video_links.create!(
          source: :youtube_official, url: "https://www.youtube.com/watch?v=abc123",
          starts_at_seconds: 132, is_active: true
        )

        get goal_path(goal)
        expect(response.body).to include("https://www.youtube.com/watch?v=abc123&amp;t=132")
      end

      it "does not append ?t= to non-YouTube URLs" do
        goal.video_links.create!(
          source: :fifa_plus, url: "https://www.fifa.com/fifaplus/clip/123",
          starts_at_seconds: 132, is_active: true
        )

        get goal_path(goal)
        expect(response.body).to include("https://www.fifa.com/fifaplus/clip/123")
        expect(response.body).not_to include("clip/123?t=")
      end
    end

    context "related lanes" do
      it "renders other goals by the same player" do
        create(:goal,
               match: match, player: messi, scoring_team: match.home_team,
               minute: 108, period: :extra_time_first, goal_type: :open_play,
               score_after_goal_home: 3, score_after_goal_away: 2)

        get goal_path(goal)
        expect(response.body).to include("Other #{messi.name} goals")
        expect(response.body).to include("108")
      end

      it "renders other goals by the same team" do
        di_maria = create(:player, name: "Ángel Di María", nationality_team: match.home_team)
        create(:goal,
               match: match, player: di_maria, scoring_team: match.home_team,
               minute: 36, period: :first_half, goal_type: :open_play,
               score_after_goal_home: 2, score_after_goal_away: 0)

        get goal_path(goal)
        expect(response.body).to include("Other #{match.home_team.name} goals")
        expect(response.body).to include("Di María")
      end
    end
  end
end
