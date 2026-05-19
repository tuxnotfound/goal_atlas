require 'rails_helper'

RSpec.describe Source, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:source)).to be_valid
    end

    it "requires a unique name" do
      create(:source, :rsssf)
      expect(build(:source, :rsssf)).not_to be_valid
    end

    it "requires a reliability" do
      expect(build(:source, reliability: nil)).not_to be_valid
    end

    it "accepts a blank URL" do
      expect(build(:source, url: nil)).to be_valid
      expect(build(:source, url: "")).to be_valid
    end

    it "rejects malformed URLs" do
      expect(build(:source, url: "not a url")).not_to be_valid
    end
  end

  describe "reliability enum" do
    it "exposes the four reliability tiers" do
      expect(Source.reliabilities.keys).to contain_exactly("official", "high", "medium", "disputed")
    end
  end
end
