require 'rails_helper'

RSpec.describe LeadParagraphHelper, type: :helper do
  describe "#match_lead" do
    context "with a regulation winner" do
      it "names the winner, loser, and final score" do
        argentina = create(:team, name: "Argentina")
        france    = create(:team, name: "France")
        tournament = create(:tournament, :wc_2022)
        match = create(:match,
          tournament: tournament,
          home_team: argentina, away_team: france,
          home_score: 2, away_score: 1,
          winner_team: argentina,
          stage: :group_stage,
          date: Date.new(2022, 11, 26))

        lead = helper.match_lead(match)

        expect(lead).to include("Argentina")
        expect(lead).to include("France")
        expect(lead).to include("2–1")
        expect(lead).to include("26 November 2022")
        expect(lead).to include("FIFA World Cup 2022")
      end
    end

    context "with a penalty shootout" do
      it "reports the after-extra-time draw and penalty result" do
        match = create(:match, :final_2022)

        lead = helper.match_lead(match)

        expect(lead).to include("Argentina")
        expect(lead).to include("France")
        expect(lead).to include("3–3")
        expect(lead).to include("after extra time")
        expect(lead).to include("4–2 on penalties")
      end
    end
  end

  describe "#tournament_lead" do
    it "names the hosts, dates, winner, and runner-up" do
      argentina = create(:team, name: "Argentina")
      france    = create(:team, name: "France")
      tournament = create(:tournament, :wc_2022,
        winner_team: argentina, runner_up_team: france)

      lead = helper.tournament_lead(tournament)

      expect(lead).to include("Qatar")
      expect(lead).to include("20 November")
      expect(lead).to include("18 December 2022")
      expect(lead).to include("Argentina")
      expect(lead).to include("France")
    end
  end
end
