require 'rails_helper'

RSpec.describe Search, type: :service do
  describe "#empty?" do
    it "is empty when query is blank" do
      expect(described_class.new("").empty?).to be true
      expect(described_class.new(nil).empty?).to be true
    end

    it "is empty when query is too short" do
      create(:player, name: "Lionel Messi")
      expect(described_class.new("a").empty?).to be true
    end
  end

  describe "team search" do
    let!(:argentina) { create(:team, name: "Argentina", fifa_code: "ARG") }
    let!(:austria)   { create(:team, name: "Austria",   fifa_code: "AUT") }

    it "finds exact-prefix matches" do
      expect(described_class.new("Argent").teams).to include(argentina)
    end

    it "is fuzzy-tolerant" do
      expect(described_class.new("Argntina").teams).to include(argentina)
    end

    it "orders by similarity" do
      results = described_class.new("Argentina").teams
      expect(results.first).to eq(argentina)
    end
  end

  describe "player search" do
    let!(:maradona) { create(:player, name: "Diego Maradona") }
    let!(:messi)    { create(:player, name: "Lionel Messi") }

    it "matches by partial surname" do
      expect(described_class.new("maradon").players).to include(maradona)
    end

    it "matches across given+family name" do
      expect(described_class.new("Lionel").players).to include(messi)
    end
  end

  describe "tournament search" do
    let!(:wc2022) { create(:tournament, year: 2022, name: "2022 FIFA World Cup") }
    let!(:wc2018) { create(:tournament, year: 2018, name: "2018 FIFA World Cup") }

    it "matches by year" do
      expect(described_class.new("2022").tournaments).to contain_exactly(wc2022)
    end

    it "matches by partial name" do
      results = described_class.new("FIFA").tournaments
      expect(results).to include(wc2022, wc2018)
    end
  end

  describe "stadium search" do
    let!(:lusail)  { create(:stadium, name: "Lusail Iconic Stadium") }
    let!(:azteca)  { create(:stadium, name: "Estadio Azteca") }

    it "matches partial name" do
      expect(described_class.new("Lusail").stadiums).to include(lusail)
    end
  end
end
