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

  has_many :goals, dependent: :restrict_with_error
  has_many :assisted_goals, class_name: "Goal", foreign_key: :assist_player_id, dependent: :nullify, inverse_of: :assist_player
  has_many :shootout_kicks, dependent: :restrict_with_error
  has_many :tournament_awards, dependent: :restrict_with_error
  has_many :player_images, dependent: :destroy

  def default_image
    player_images.kept.active.default.first || player_images.kept.active.ordered.first
  end

  def portrait_image
    player_images.kept.active.portrait.first || default_image
  end

  def image_for(tournament)
    return default_image if tournament.blank?
    player_images.kept.active.joins(:player_image_taggings)
                 .where(player_image_taggings: { tournament_id: tournament.id })
                 .ordered.first || default_image
  end

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
#  index_players_on_name_trgm            (name) USING gin
#  index_players_on_nationality_team_id  (nationality_team_id)
#  index_players_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (nationality_team_id => teams.id)
#
