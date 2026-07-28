require "rails_helper"

RSpec.describe TournamentFinalizer do
  let(:tournament) { create(:tournament, year: 2026, total_matches: 4, total_goals: nil) }

  let(:champion)  { create(:team, name: "Spain",     fifa_code: "ESP") }
  let(:runner_up) { create(:team, name: "Argentina", fifa_code: "ARG") }
  let(:third)     { create(:team, name: "England",   fifa_code: "ENG") }
  let(:fourth)    { create(:team, name: "France",    fifa_code: "FRA") }

  # A minimal but complete tournament: two semi-finals, a third-place playoff
  # and a final. 2 + 1 + 3 + 1 = 7 goals across 4 matches.
  def build_complete_tournament
    create(:match, tournament: tournament, stage: :semi_final, group_letter: nil, match_number: 1,
                   home_team: fourth, away_team: champion, home_score: 0, away_score: 2,
                   winner_team: champion, date: Date.new(2026, 7, 14))
    create(:match, tournament: tournament, stage: :semi_final, group_letter: nil, match_number: 2,
                   home_team: third, away_team: runner_up, home_score: 0, away_score: 1,
                   winner_team: runner_up, date: Date.new(2026, 7, 15))
    create(:match, tournament: tournament, stage: :third_place_playoff, group_letter: nil, match_number: 3,
                   home_team: fourth, away_team: third, home_score: 1, away_score: 2,
                   winner_team: third, date: Date.new(2026, 7, 18))
    create(:match, tournament: tournament, stage: :final, group_letter: nil, match_number: 4,
                   home_team: champion, away_team: runner_up, home_score: 1, away_score: 0,
                   winner_team: champion, date: Date.new(2026, 7, 19))
  end

  describe "a complete tournament" do
    before { build_complete_tournament }

    it "derives the podium from the final and the third-place playoff" do
      described_class.call(tournament)

      expect(tournament.reload).to have_attributes(
        winner_team:       champion,
        runner_up_team:    runner_up,
        third_place_team:  third,
        fourth_place_team: fourth
      )
    end

    it "derives the totals from the played matches" do
      described_class.call(tournament)

      expect(tournament.reload).to have_attributes(total_matches: 4, total_goals: 7)
    end

    it "reports what it changed" do
      result = described_class.call(tournament)

      expect(result.complete).to be(true)
      expect(result.changed).to contain_exactly(
        :winner_team_id, :runner_up_team_id, :third_place_team_id,
        :fourth_place_team_id, :total_goals
      )
    end

    it "is idempotent — a second run changes nothing" do
      described_class.call(tournament)

      expect(described_class.call(tournament).changed).to be_empty
    end

    it "counts cumulative extra-time scores instead of adding them to regulation" do
      Match.find_by(tournament: tournament, stage: :final)
           .update!(home_score: 0, away_score: 0,
                    home_score_after_extra_time: 1, away_score_after_extra_time: 0,
                    result_type: :after_extra_time)

      described_class.call(tournament)

      expect(tournament.reload.total_goals).to eq(7)
    end

    it "ignores penalty shootouts, matching FIFA's goal count" do
      Match.find_by(tournament: tournament, stage: :final)
           .update!(home_score: 1, away_score: 1,
                    home_penalties: 4, away_penalties: 2, result_type: :after_penalties)

      described_class.call(tournament)

      expect(tournament.reload.total_goals).to eq(8)
    end
  end

  describe "an incomplete tournament" do
    before do
      build_complete_tournament
      # A still-TBD bracket placeholder, exactly as the WC2026 knockout seeds it.
      create(:match, tournament: tournament, stage: :quarter_final, group_letter: nil, match_number: 5,
                     result_type: :scheduled, home_team: nil, away_team: nil,
                     home_source_label: "W89", away_source_label: "W90",
                     home_score: 0, away_score: 0, date: Date.new(2026, 7, 9))
    end

    it "writes nothing while any fixture is still unplayed" do
      result = described_class.call(tournament)

      expect(result.complete).to be(false)
      expect(result.changed).to be_empty
      expect(tournament.reload).to have_attributes(winner_team: nil, total_goals: nil)
    end
  end

  describe "an edition with no third-place playoff" do
    before do
      create(:match, tournament: tournament, stage: :final, group_letter: nil, match_number: 1,
                     home_team: champion, away_team: runner_up, home_score: 2, away_score: 1,
                     winner_team: champion, date: Date.new(2026, 7, 19))
    end

    it "fills the places it can and leaves the rest untouched" do
      tournament.update!(third_place_team: third, fourth_place_team: fourth)

      described_class.call(tournament)

      # A missing playoff must never blank out a hand-seeded 3rd/4th place.
      expect(tournament.reload).to have_attributes(
        winner_team:       champion,
        runner_up_team:    runner_up,
        third_place_team:  third,
        fourth_place_team: fourth
      )
    end
  end

  describe "a tournament with no matches seeded yet" do
    it "is not considered complete" do
      expect(described_class.call(tournament).complete).to be(false)
    end
  end
end
