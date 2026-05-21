require 'rails_helper'

RSpec.describe PlayerTournamentRecord, type: :service do
  let(:tournament_2022) { create(:tournament, year: 2022) }
  let(:tournament_2018) { create(:tournament, year: 2018) }
  let(:team)            { create(:team, name: "Argentina", fifa_code: "ARG") }
  let(:opponent)        { create(:team, name: "France",    fifa_code: "FRA") }
  let(:player)          { create(:player, name: "Lionel Messi", nationality_team: team) }

  describe ".for_player" do
    it "returns empty when player has no recorded contributions" do
      expect(described_class.for_player(player)).to be_empty
    end

    it "produces one record per tournament the player appears in, chronological" do
      m22 = create(:match, tournament: tournament_2022, home_team: team, away_team: opponent)
      m18 = create(:match, tournament: tournament_2018, home_team: team, away_team: opponent,
                           date: Date.new(2018, 6, 16))
      create(:goal, match: m22, player: player, scoring_team: team)
      create(:goal, match: m18, player: player, scoring_team: team)

      years = described_class.for_player(player).map { |r| r.tournament.year }
      expect(years).to eq([2018, 2022])
    end

    it "includes a tournament where the player only took shootout kicks" do
      m = create(:match, tournament: tournament_2022, home_team: team, away_team: opponent)
      create(:shootout_kick, match: m, team: team, player: player, kick_order: 1, was_scored: true)
      expect(described_class.for_player(player).size).to eq(1)
    end

    it "includes a tournament where the player only won an award" do
      create(:tournament_award, tournament: tournament_2022, player: player, award_type: :golden_glove)
      expect(described_class.for_player(player).size).to eq(1)
    end
  end

  describe "counts" do
    it "counts goals, assists, shootouts, awards per tournament" do
      m = create(:match, tournament: tournament_2022, home_team: team, away_team: opponent)
      teammate = create(:player, name: "Ángel Di María")
      create(:goal, match: m, player: player,   scoring_team: team, assist_player: teammate)
      create(:goal, match: m, player: teammate, scoring_team: team, assist_player: player, minute: 36)
      create(:shootout_kick, match: m, team: team, player: player, kick_order: 1, was_scored: true)
      create(:shootout_kick, match: m, team: team, player: player, kick_order: 3, was_scored: false)
      create(:tournament_award, tournament: tournament_2022, player: player, award_type: :golden_ball)

      record = described_class.for_player(player).first
      expect(record.goals_count).to eq(1)
      expect(record.assists_count).to eq(1)
      expect(record.shootout_kicks_count).to eq(2)
      expect(record.shootout_kicks_scored).to eq(1)
      expect(record.shootout_kicks_missed).to eq(1)
      expect(record.awards.size).to eq(1)
      expect(record.has_award?).to be true
    end
  end
end
