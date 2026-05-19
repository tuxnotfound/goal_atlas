class Team < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :name, use: :slugged

  CONFEDERATIONS = {
    uefa: 0,
    conmebol: 1,
    concacaf: 2,
    afc: 3,
    caf: 4,
    ofc: 5
  }.freeze

  enum :confederation, CONFEDERATIONS

  belongs_to :successor_team, class_name: "Team", optional: true
  has_many :predecessor_teams, class_name: "Team", foreign_key: :successor_team_id, dependent: :nullify, inverse_of: :successor_team

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :country_code, presence: true, length: { in: 2..3 }
  validates :fifa_code, length: { is: 3 }, allow_blank: true

  scope :active_in_year, ->(year) {
    where("(active_from IS NULL OR active_from <= ?) AND (active_until IS NULL OR active_until >= ?)", year, year)
  }
end
