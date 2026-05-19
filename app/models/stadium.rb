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
