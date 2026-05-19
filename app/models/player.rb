class Player < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :name, use: :slugged

  POSITIONS = {
    goalkeeper: 0,
    defender: 1,
    midfielder: 2,
    forward: 3
  }.freeze

  enum :position, POSITIONS

  belongs_to :nationality_team, class_name: "Team", optional: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
