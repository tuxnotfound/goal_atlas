require 'rails_helper'

RSpec.describe PlayerImage, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:player_image)).to be_valid
    end

    it "requires a URL" do
      expect(build(:player_image, url: nil)).not_to be_valid
    end

    it "rejects malformed URLs" do
      expect(build(:player_image, url: "not a url")).not_to be_valid
    end

    it "rejects duplicate URLs for the same player" do
      existing = create(:player_image)
      dup = build(:player_image, player: existing.player, url: existing.url)
      expect(dup).not_to be_valid
    end

    it "allows the same URL across different players" do
      first = create(:player_image)
      second = build(:player_image, url: first.url)
      expect(second).to be_valid
    end
  end

  describe "default scoping" do
    it "enforces one default image per player at the DB level" do
      player = create(:player)
      create(:player_image, :default, player: player)
      duplicate_default = build(:player_image, :default, player: player)
      expect { duplicate_default.save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".default and .active scopes" do
    let(:player) { create(:player) }
    let!(:default_image)  { create(:player_image, :default, player: player) }
    let!(:inactive_image) { create(:player_image, :inactive, player: player, position: 1) }
    let!(:normal_image)   { create(:player_image, player: player, position: 2) }

    it "scopes .default to images flagged as default" do
      expect(PlayerImage.default).to contain_exactly(default_image)
    end

    it "scopes .active to images flagged active" do
      expect(PlayerImage.active).to contain_exactly(default_image, normal_image)
    end
  end

  describe "tournaments association" do
    it "associates many tournaments via player_image_taggings" do
      image = create(:player_image)
      t1 = create(:tournament, year: 2018)
      t2 = create(:tournament, year: 2022)
      image.tournaments << t1
      image.tournaments << t2
      expect(image.reload.tournaments).to contain_exactly(t1, t2)
    end
  end

  describe "#attribution_line" do
    it "joins author and license with separator" do
      img = build(:player_image, author: "Jane Doe", license: "CC BY 4.0")
      expect(img.attribution_line).to eq("Jane Doe · CC BY 4.0")
    end

    it "returns nil when both author and license are blank" do
      img = build(:player_image, author: nil, license: nil)
      expect(img.attribution_line).to be_nil
    end
  end
end
