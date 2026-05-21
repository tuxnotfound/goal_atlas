require 'rails_helper'

RSpec.describe TeamTournamentRecord, type: :service do
  let(:tournament) { create(:tournament, year: 2022) }
  let(:team)       { create(:team, name: "Argentina", fifa_code: "ARG") }
  let(:opponent)   { create(:team, name: "France",    fifa_code: "FRA") }

  describe "#matches_played, wins, draws, losses" do
    it "counts a regulation win" do
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     home_score: 2, away_score: 1, winner_team: team)
      r = described_class.new(team, tournament)
      expect(r.matches_played).to eq(1)
      expect(r.wins).to eq(1)
      expect(r.losses).to eq(0)
      expect(r.draws).to eq(0)
    end

    it "counts a draw when no winner is set" do
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     home_score: 1, away_score: 1, winner_team: nil)
      r = described_class.new(team, tournament)
      expect(r.draws).to eq(1)
      expect(r.wins).to eq(0)
    end

    it "counts a shootout win as a win (winner_team_id set)" do
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     home_score: 2, away_score: 2,
                     home_score_after_extra_time: 3, away_score_after_extra_time: 3,
                     home_penalties: 4, away_penalties: 2,
                     winner_team: team, result_type: :after_penalties)
      r = described_class.new(team, tournament)
      expect(r.wins).to eq(1)
    end
  end

  describe "#goals_for and #goals_against" do
    it "uses post-ET score when extra time was played" do
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     home_score: 2, away_score: 2,
                     home_score_after_extra_time: 3, away_score_after_extra_time: 3,
                     winner_team: team, result_type: :after_penalties)
      r = described_class.new(team, tournament)
      expect(r.goals_for).to eq(3)
      expect(r.goals_against).to eq(3)
    end

    it "uses regulation score when no extra time" do
      create(:match, tournament: tournament, home_team: opponent, away_team: team,
                     home_score: 1, away_score: 4, winner_team: team)
      r = described_class.new(team, tournament)
      expect(r.goals_for).to eq(4)
      expect(r.goals_against).to eq(1)
    end

    it "sums across multiple matches" do
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     home_score: 2, away_score: 0, winner_team: team)
      create(:match, tournament: tournament, home_team: opponent, away_team: team,
                     home_score: 1, away_score: 3, winner_team: team,
                     date: Date.new(2022, 11, 25))
      r = described_class.new(team, tournament)
      expect(r.goals_for).to eq(5)
      expect(r.goals_against).to eq(1)
      expect(r.goal_difference).to eq(4)
    end
  end

  describe "#finish_label" do
    it "returns 'Champions' when team is tournament.winner_team" do
      tournament.update!(winner_team: team)
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     stage: :final, winner_team: team, home_score: 1, away_score: 0)
      r = described_class.new(team, tournament)
      expect(r.finish_label).to eq("Champions")
      expect(r.champion?).to be true
    end

    it "returns 'Runners-up' when team lost the final" do
      tournament.update!(runner_up_team: team)
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     stage: :final, winner_team: opponent, home_score: 0, away_score: 1)
      r = described_class.new(team, tournament)
      expect(r.finish_label).to eq("Runners-up")
    end

    it "falls back to deepest stage reached" do
      create(:match, tournament: tournament, home_team: team, away_team: opponent,
                     stage: :round_of_16, winner_team: opponent, home_score: 0, away_score: 1)
      r = described_class.new(team, tournament)
      expect(r.finish_label).to eq("Round of 16")
      expect(r.podium?).to be false
    end
  end

  describe ".for_team" do
    it "returns one record per tournament the team played in, ordered chronologically" do
      wc18 = create(:tournament, year: 2018)
      create(:match, tournament: tournament, home_team: team, away_team: opponent, date: Date.new(2022, 11, 22))
      create(:match, tournament: wc18,       home_team: team, away_team: opponent, date: Date.new(2018, 6, 16))

      records = described_class.for_team(team)
      expect(records.map { |r| r.tournament.year }).to eq([2018, 2022])
    end

    it "returns an empty array when the team has played no matches" do
      expect(described_class.for_team(team)).to be_empty
    end
  end
end
