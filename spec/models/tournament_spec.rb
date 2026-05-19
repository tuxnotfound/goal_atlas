require 'rails_helper'

RSpec.describe Tournament, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:tournament)).to be_valid
    end

    it "requires year, slug, name" do
      expect(build(:tournament, year: nil)).not_to be_valid
      expect(build(:tournament, name: nil)).not_to be_valid
    end

    it "enforces unique year" do
      create(:tournament, :wc_2022)
      duplicate = build(:tournament, :wc_2022)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:year]).to include("has already been taken")
    end

    it "rejects implausible years" do
      expect(build(:tournament, year: 1899)).not_to be_valid
      expect(build(:tournament, year: 2100)).not_to be_valid
    end

    it "rejects end_date before start_date" do
      tournament = build(:tournament,
                          start_date: Date.new(2022, 12, 18),
                          end_date: Date.new(2022, 11, 20))
      expect(tournament).not_to be_valid
      expect(tournament.errors[:end_date]).to be_present
    end
  end

  describe "slug" do
    it "generates a friendly slug from year" do
      tournament = create(:tournament, :wc_2022)
      expect(tournament.slug).to eq("world-cup-2022")
    end
  end

  describe "host_countries" do
    it "supports a single host" do
      tournament = create(:tournament, :wc_2022)
      expect(tournament.host_countries).to eq(["Qatar"])
    end

    it "supports joint hosts (e.g. 2026)" do
      tournament = create(:tournament, :wc_2026_joint_host)
      expect(tournament.host_countries).to contain_exactly("Mexico", "United States", "Canada")
    end
  end

  describe "podium associations" do
    it "links winner / runner-up / third / fourth to teams" do
      argentina = create(:team, name: "Argentina")
      france    = create(:team, name: "France")
      croatia   = create(:team, name: "Croatia")
      morocco   = create(:team, name: "Morocco")

      tournament = create(:tournament, :wc_2022,
                          winner_team: argentina,
                          runner_up_team: france,
                          third_place_team: croatia,
                          fourth_place_team: morocco)

      expect(tournament.winner_team).to eq(argentina)
      expect(tournament.runner_up_team).to eq(france)
      expect(tournament.third_place_team).to eq(croatia)
      expect(tournament.fourth_place_team).to eq(morocco)
    end

    it "allows podium teams to be unset" do
      expect(build(:tournament)).to be_valid
    end
  end
end
