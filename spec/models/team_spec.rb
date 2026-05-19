require 'rails_helper'

RSpec.describe Team, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:team)).to be_valid
    end

    it "requires a name" do
      expect(build(:team, name: nil)).not_to be_valid
    end

    it "requires a country_code of 2 or 3 chars" do
      expect(build(:team, country_code: "B")).not_to be_valid
      expect(build(:team, country_code: "BR")).to be_valid
      expect(build(:team, country_code: "BRA")).to be_valid
      expect(build(:team, country_code: "BRAZ")).not_to be_valid
    end

    it "enforces unique slugs at the DB level" do
      create(:team, name: "Brazil")
      duplicate = build(:team, name: "Brazil B Team")
      duplicate.slug = "brazil" # force collision past friendly_id's auto-incrementing
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "auto-generates distinct slugs when names collide" do
      first  = create(:team, name: "Brazil")
      second = create(:team, name: "Brazil")
      expect(first.slug).to eq("brazil")
      expect(second.slug).not_to eq(first.slug)
    end
  end

  describe "associations" do
    it "links successor and predecessor teams" do
      germany = create(:team, :germany)
      west_germany = create(:team, :west_germany, successor_team: germany)

      expect(west_germany.successor_team).to eq(germany)
      expect(germany.predecessor_teams).to include(west_germany)
    end

    it "nullifies successor_team_id when the successor is destroyed" do
      germany = create(:team, :germany)
      west_germany = create(:team, :west_germany, successor_team: germany)

      germany.destroy
      expect(west_germany.reload.successor_team).to be_nil
    end
  end

  describe ".active_in_year" do
    it "filters teams by their active_from / active_until window" do
      west_germany = create(:team, :west_germany)            # 1908..1990
      east_germany = create(:team, name: "East Germany",
                                    country_code: "DE",
                                    confederation: :uefa,
                                    active_from: 1952,
                                    active_until: 1990)

      expect(Team.active_in_year(1974)).to include(west_germany, east_germany)
      expect(Team.active_in_year(1948)).to include(west_germany)
      expect(Team.active_in_year(1948)).not_to include(east_germany)
      expect(Team.active_in_year(2000)).not_to include(west_germany, east_germany)
    end

    it "includes teams with no active window (assumed always active)" do
      brazil = create(:team, name: "Brazil")
      expect(Team.active_in_year(1930)).to include(brazil)
      expect(Team.active_in_year(2022)).to include(brazil)
    end
  end

  describe "discard" do
    it "soft-deletes via discard" do
      team = create(:team)
      team.discard
      expect(team.discarded?).to be true
      expect(Team.kept).not_to include(team)
    end
  end

  describe "confederation enum" do
    it "exposes confederation values" do
      expect(Team.confederations.keys).to contain_exactly("uefa", "conmebol", "concacaf", "afc", "caf", "ofc")
    end
  end
end
