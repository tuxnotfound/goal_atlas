require 'rails_helper'

RSpec.describe Stadium, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:stadium)).to be_valid
    end

    it "requires name, city, country" do
      expect(build(:stadium, name: nil)).not_to be_valid
      expect(build(:stadium, city: nil)).not_to be_valid
      expect(build(:stadium, country: nil)).not_to be_valid
    end

    it "validates latitude and longitude ranges" do
      expect(build(:stadium, latitude: 91)).not_to be_valid
      expect(build(:stadium, latitude: -91)).not_to be_valid
      expect(build(:stadium, longitude: 181)).not_to be_valid
      expect(build(:stadium, longitude: -181)).not_to be_valid
    end

    it "rejects non-positive capacity" do
      expect(build(:stadium, current_capacity: 0)).not_to be_valid
      expect(build(:stadium, current_capacity: -1)).not_to be_valid
    end

    it "allows blank capacity and coordinates" do
      expect(build(:stadium, current_capacity: nil, latitude: nil, longitude: nil)).to be_valid
    end
  end

  describe "slug" do
    it "auto-generates from name" do
      stadium = create(:stadium, :lusail)
      expect(stadium.slug).to eq("lusail-iconic-stadium")
    end
  end

  describe "discard" do
    it "soft-deletes" do
      stadium = create(:stadium)
      stadium.discard
      expect(Stadium.kept).not_to include(stadium)
    end
  end
end

# == Schema Information
#
# Table name: stadiums
#
#  id               :bigint           not null, primary key
#  city             :string           not null
#  country          :string           not null
#  country_code     :string
#  current_capacity :integer
#  discarded_at     :datetime
#  latitude         :decimal(9, 6)
#  longitude        :decimal(9, 6)
#  name             :string           not null
#  notes            :text
#  slug             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_stadiums_on_city          (city)
#  index_stadiums_on_country_code  (country_code)
#  index_stadiums_on_discarded_at  (discarded_at)
#  index_stadiums_on_name          (name)
#  index_stadiums_on_slug          (slug) UNIQUE
#
