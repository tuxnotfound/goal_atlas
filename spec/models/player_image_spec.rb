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

  describe "#thumbnail" do
    it "swaps the size segment of a Wikimedia thumbnail URL" do
      img = build(:player_image,
        thumbnail_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Lionel_Messi.jpg/600px-Lionel_Messi.jpg")
      expect(img.thumbnail(width: 120)).to eq(
        "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Lionel_Messi.jpg/120px-Lionel_Messi.jpg"
      )
    end

    it "returns the underlying URL unchanged when no size segment is present" do
      img = build(:player_image,
                  url: "https://example.com/photo.jpg",
                  thumbnail_url: "https://example.com/photo.jpg")
      expect(img.thumbnail(width: 200)).to eq("https://example.com/photo.jpg")
    end

    it "falls back to the original URL when thumbnail_url is blank" do
      img = build(:player_image,
                  url: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/X.jpg/600px-X.jpg",
                  thumbnail_url: nil)
      expect(img.thumbnail(width: 80)).to include("80px-X.jpg")
    end
  end
end

# == Schema Information
#
# Table name: player_images
#
#  id                 :bigint           not null, primary key
#  author             :string
#  commons_categories :string           default([]), is an Array
#  description        :text
#  discarded_at       :datetime
#  fetched_at         :datetime
#  image_height       :integer
#  image_width        :integer
#  is_active          :boolean          default(TRUE), not null
#  is_default         :boolean          default(FALSE), not null
#  is_portrait        :boolean          default(FALSE), not null
#  license            :string
#  license_url        :string
#  notes              :text
#  position           :integer          default(0), not null
#  source_url         :string
#  thumbnail_url      :string
#  url                :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  player_id          :bigint           not null
#
# Indexes
#
#  index_player_images_on_discarded_at          (discarded_at)
#  index_player_images_on_player_id             (player_id)
#  index_player_images_on_player_id_and_url     (player_id,url) UNIQUE
#  index_player_images_one_default_per_player   (player_id,is_default) UNIQUE WHERE (is_default = true)
#  index_player_images_one_portrait_per_player  (player_id,is_portrait) UNIQUE WHERE (is_portrait = true)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
