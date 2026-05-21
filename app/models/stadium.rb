class Stadium < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :city, presence: true
  validates :country, presence: true
  validates :country_code, length: { in: 2..3 }, allow_blank: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :current_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
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
#  index_stadiums_on_name_trgm     (name) USING gin
#  index_stadiums_on_slug          (slug) UNIQUE
#
