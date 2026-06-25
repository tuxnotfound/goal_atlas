require 'rails_helper'

RSpec.describe "Goals", type: :request do
  describe "GET /goals" do
    let(:match) { create(:match, :final_2022) }
    let(:messi) { create(:player, :messi, nationality_team: match.home_team) }

    def make_goal(attrs)
      defaults = {
        match: match, player: messi, scoring_team: match.home_team,
        period: :first_half, score_after_goal_home: 1, score_after_goal_away: 0
      }
      create(:goal, defaults.merge(attrs))
    end

    it "renders the index successfully" do
      get goals_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Goals")
    end

    it "filters by goal_type" do
      penalty = make_goal(minute: 23, goal_type: :penalty)
      open    = make_goal(minute: 36, goal_type: :open_play, score_after_goal_home: 2)

      get goals_path(type: "penalty")
      expect(response.body).to include(goal_path(penalty))
      expect(response.body).not_to include(goal_path(open))
    end

    it "filters by stage" do
      group_match = create(:match,
                           tournament: match.tournament,
                           stage: :group_stage, date: Date.new(2022, 11, 20),
                           home_team: match.home_team, away_team: match.away_team,
                           home_score: 1, away_score: 0, match_number: 2)
      final_goal = make_goal(minute: 23)
      group_goal = make_goal(match: group_match, minute: 10)

      get goals_path(stage: "final")
      expect(response.body).to include(goal_path(final_goal))
      expect(response.body).not_to include(goal_path(group_goal))
    end

    it "filters by tag (slug)" do
      tagged = make_goal(minute: 23)
      untagged = make_goal(minute: 36, score_after_goal_home: 2)
      tag = GoalTag.create!(name: "Long Range")
      create(:goal_tagging, goal: tagged, goal_tag: tag)

      get goals_path(tag: "long-range")
      expect(response.body).to include(goal_path(tagged))
      expect(response.body).not_to include(goal_path(untagged))
    end

    it "filters by tournament year" do
      other_tournament = create(:tournament, year: 2018, name: "FIFA World Cup 2018", host_countries: ["Russia"])
      other_match = create(:match,
                           tournament: other_tournament,
                           stage: :final, date: Date.new(2018, 7, 15),
                           home_team: match.home_team, away_team: match.away_team,
                           home_score: 4, away_score: 2, match_number: 64)
      g_2022 = make_goal(minute: 23)
      g_2018 = make_goal(match: other_match, minute: 10)

      get goals_path(tournament: "2022")
      expect(response.body).to include(goal_path(g_2022))
      expect(response.body).not_to include(goal_path(g_2018))
    end

    it "combines filters (type + stage)" do
      penalty_final = make_goal(minute: 23, goal_type: :penalty)
      open_final    = make_goal(minute: 36, goal_type: :open_play, score_after_goal_home: 2)

      get goals_path(type: "penalty", stage: "final")
      expect(response.body).to include(goal_path(penalty_final))
      expect(response.body).not_to include(goal_path(open_final))
    end

    it "ignores unknown filter values" do
      make_goal(minute: 23)
      get goals_path(type: "not-a-real-type")
      expect(response).to have_http_status(:ok)
      # No filter applied, so the goal is still shown.
      expect(response.body).to include("Lionel Messi")
    end

    it "shows an empty-state message when no goals match" do
      make_goal(minute: 23, goal_type: :penalty)
      get goals_path(type: "free_kick") # exists in enum but no matching goal
      expect(response.body).to include("No goals match these filters")
    end
  end

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

    context "own goals" do
      # Own goal: the away GK (nationality = away/France team) puts it into
      # their own net, so it is credited to the home/Argentina team.
      let(:own_goal_scorer) { create(:player, name: "Hugo Lloris", nationality_team: match.away_team) }
      let!(:own_goal) do
        create(:goal, :own_goal,
               match: match, player: own_goal_scorer, scoring_team: match.home_team,
               minute: 10, period: :first_half,
               score_after_goal_home: 1, score_after_goal_away: 0)
      end

      it "labels the goal page as an own goal and names the scorer's real team" do
        get goal_path(own_goal)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Own Goal")
        # Scorer's actual side and the credited side are both named explicitly.
        expect(response.body).to include("Own goal by")
        expect(response.body).to include(match.away_team.name) # scorer's real team
        expect(response.body).to include("credited to")
      end

      it "marks the own goal in the match score rows with an OG badge" do
        get match_path(match)
        expect(response.body).to include("Own goal") # badge title/aria
        expect(response.body).to include(own_goal_scorer.name)
      end
    end

    context "goal tags" do
      it "renders tag chips when tags are applied" do
        long_range = GoalTag.create!(name: "Long Range")
        create(:goal_tagging, goal: goal, goal_tag: long_range)

        get goal_path(goal)
        expect(response.body).to include("Long Range")
        expect(response.body).to include("rounded-full")
      end

      it "renders no tag chip block when there are no tags" do
        get goal_path(goal)
        expect(response.body).not_to include("Long Range")
      end
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

  end
end
