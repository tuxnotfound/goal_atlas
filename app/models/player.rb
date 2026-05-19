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

# == Schema Information
#
# Table name: players
#
#  id                  :bigint           not null, primary key
#  birth_date          :date
#  discarded_at        :datetime
#  name                :string           not null
#  name_local          :string
#  position            :integer
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  nationality_team_id :bigint
#
# Indexes
#
#  index_players_on_discarded_at         (discarded_at)
#  index_players_on_name                 (name)
#  index_players_on_nationality_team_id  (nationality_team_id)
#  index_players_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (nationality_team_id => teams.id)
#
