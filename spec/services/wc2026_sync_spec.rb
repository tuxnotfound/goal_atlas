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
end
