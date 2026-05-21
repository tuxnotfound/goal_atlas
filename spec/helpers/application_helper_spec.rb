require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#avatar_initials" do
    it "takes the first letter of the first two name tokens" do
      expect(helper.avatar_initials("Diego Maradona")).to eq("DM")
    end

    it "handles a single-token name (no given name)" do
      expect(helper.avatar_initials("Pelé")).to eq("P")
    end

    it "handles hyphenated surnames" do
      expect(helper.avatar_initials("Hong Myung-bo")).to eq("HM")
    end

    it "uppercases" do
      expect(helper.avatar_initials("paul pogba")).to eq("PP")
    end

    it "returns ? when name is blank" do
      expect(helper.avatar_initials(nil)).to eq("?")
      expect(helper.avatar_initials("")).to eq("?")
    end
  end
end
