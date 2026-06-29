require 'rails_helper'

RSpec.describe Wc2026Sync, type: :service do
  # Stub client: returns canned /players?id=N payloads, never hits the network.
  class FakeClient
    def initialize(details) = @details = details
    def player_details(id:, season:)
      { "response" => [{ "player" => @details[id] }] }
    end
  end

  let(:argentina) { create(:team, name: "Argentina", fifa_code: "ARG") }

  def find_or_create(details, api_id, short_name, team)
    described_class.new(client: FakeClient.new(details))
                   .send(:find_or_create_player, api_id, short_name, team)
  end

  describe "name derivation (#find_or_create_player)" do
    it "expands an abbreviated api `name` to the known form using firstname" do
      details = { 154 => { "name" => "L. Messi", "firstname" => "Lionel Andrés",
                           "lastname" => "Messi Cuccittini" } }
      player = find_or_create(details, 154, "L. Messi", argentina)
      expect(player.name).to eq("Lionel Messi") # not "Lionel Messi Cuccittini"
    end

    it "uses a full (non-abbreviated) api `name` as-is" do
      iraq = create(:team, name: "Iraq", fifa_code: "IRQ")
      details = { 49451 => { "name" => "Aymen Hussein", "firstname" => "Aymen Hussein",
                             "lastname" => "Ghadhban" } }
      expect(find_or_create(details, 49451, "Aymen Hussein", iraq).name).to eq("Aymen Hussein")
    end

    it "drops a middle name buried in the lastname field" do
      norway = create(:team, name: "Norway", fifa_code: "NOR")
      details = { 1100 => { "name" => "E. Haaland", "firstname" => "Erling",
                            "lastname" => "Braut Haaland" } }
      expect(find_or_create(details, 1100, "E. Haaland", norway).name).to eq("Erling Haaland")
    end
  end

  describe "dedup against an existing record" do
    it "links the existing player instead of creating a duplicate, and backfills the api id" do
      existing = create(:player, name: "Lionel Messi", nationality_team: argentina)
      details  = { 154 => { "name" => "L. Messi", "firstname" => "Lionel Andrés",
                            "lastname" => "Messi Cuccittini" } }

      result = nil
      expect { result = find_or_create(details, 154, "L. Messi", argentina) }
        .not_to change(Player, :count)
      expect(result.id).to eq(existing.id)
      expect(existing.reload.api_football_player_id).to eq(154)
    end
  end

  describe "lineup participation (#sync_participations_for)" do
    # Stub client: returns canned /fixtures/lineups + (empty) /players details.
    class LineupClient
      def initialize(lineups:, details: {})
        @lineups = lineups
        @details = details
      end

      def fixture_lineups(fixture_id:) = { "response" => @lineups }
      def player_details(id:, season:) = { "response" => [{ "player" => @details[id] }] }
    end

    let(:tournament) { create(:tournament, :wc_2026_joint_host) }
    let(:portugal)   { create(:team, name: "Portugal", fifa_code: "POR") }
    let(:morocco)    { create(:team, name: "Morocco",  fifa_code: "MAR") }
    let(:match) do
      create(:match, tournament: tournament, home_team: portugal, away_team: morocco,
                     result_type: :regulation, date: Date.new(2026, 6, 18))
    end
    let(:fx)       { { "fixture" => { "id" => 5000 } } }
    let(:team_map) { { 1 => portugal, 2 => morocco } }

    def lineup(api_team_id, players)
      { "team" => { "id" => api_team_id },
        "startXI" => players.map { |p| { "player" => p } },
        "substitutes" => [] }
    end

    def run_participation_sync(lineups, details: {})
      described_class.new(client: LineupClient.new(lineups: lineups, details: details))
                     .send(:sync_participations_for, match, fx, team_map)
    end

    it "records participation for an existing non-scorer who appeared" do
      ronaldo = create(:player, name: "Cristiano Ronaldo", nationality_team: portugal,
                       api_football_player_id: 874)

      expect { run_participation_sync([lineup(1, [{ "id" => 874, "name" => "Cristiano Ronaldo" }])]) }
        .to change { TournamentParticipation.where(player_id: ronaldo.id, tournament_id: tournament.id).count }.by(1)
    end

    it "never creates a Player for a squad member we don't already have" do
      create(:player, name: "Cristiano Ronaldo", nationality_team: portugal, api_football_player_id: 874)
      lineups = [lineup(1, [{ "id" => 874, "name" => "Cristiano Ronaldo" },
                            { "id" => 99_999, "name" => "Unknown Newcomer" }]),
                 lineup(2, [{ "id" => 88_888, "name" => "Some Moroccan" }])]

      expect { run_participation_sync(lineups) }.not_to change(Player, :count)
      expect(TournamentParticipation.count).to eq(1) # only the existing player
    end

    it "matches an existing player by abbreviated name once the surname is in our roster, backfilling the id" do
      bruno   = create(:player, name: "Bruno Fernandes", nationality_team: portugal) # no api id yet
      details = { 999 => { "name" => "B. Fernandes", "firstname" => "Bruno", "lastname" => "Fernandes" } }
      lineups = [lineup(1, [{ "id" => 999, "name" => "B. Fernandes" }])]

      expect { run_participation_sync(lineups, details: details) }
        .to change { TournamentParticipation.where(player_id: bruno.id, tournament_id: tournament.id).count }.by(1)
      expect(bruno.reload.api_football_player_id).to eq(999)
    end

    it "is idempotent and stamps lineups_synced_at to skip re-runs" do
      create(:player, name: "Cristiano Ronaldo", nationality_team: portugal, api_football_player_id: 874)
      lineups = [lineup(1, [{ "id" => 874, "name" => "Cristiano Ronaldo" }])]

      run_participation_sync(lineups)
      expect(match.reload.lineups_synced_at).to be_present
      expect { run_participation_sync(lineups) }.not_to change(TournamentParticipation, :count)
    end
  end

  describe "bracket populate hook (#call)" do
    let(:client) { instance_double(ApiFootballClient) }
    subject(:sync) { described_class.new(client: client) }

    before do
      create(:tournament, :wc_2026_joint_host)
      allow(client).to receive(:teams).and_return({ "response" => [] })
    end

    it "does not re-populate the bracket when nothing changed" do
      allow(client).to receive(:fixtures).and_return({ "response" => [] })
      expect(Wc2026BracketPopulator).not_to receive(:call)
      expect(sync.call[:bracket]).to be_nil
    end

    it "re-populates the bracket after a result changes, surfacing its stats" do
      allow(client).to receive(:fixtures).and_return({ "response" => [{}] })
      allow(sync).to receive(:sync_fixture) { sync.stats[:updated] += 1 }
      populator_stats = { changed: 1, filled: 17, total: 32 }
      expect(Wc2026BracketPopulator).to receive(:call).and_return(populator_stats)

      expect(sync.call[:bracket]).to eq(populator_stats)
    end

    it "never lets a bracket failure break the result sync" do
      allow(client).to receive(:fixtures).and_return({ "response" => [{}] })
      allow(sync).to receive(:sync_fixture) { sync.stats[:updated] += 1 }
      allow(Wc2026BracketPopulator).to receive(:call).and_raise(StandardError, "boom")

      result = nil
      expect { result = sync.call }.not_to raise_error
      expect(result[:bracket]).to eq({ error: "boom" })
    end
  end
end
