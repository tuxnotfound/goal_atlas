class ShootoutKick < ApplicationRecord
  include Discard::Model

  belongs_to :match
  belongs_to :team
  belongs_to :player

  validates :kick_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :was_scored, inclusion: { in: [true, false] }
  validate :team_is_in_match

  scope :ordered, -> { order(:kick_order) }

  private

  def team_is_in_match
    return if match.blank? || team_id.blank?
    return if [match.home_team_id, match.away_team_id].include?(team_id)
    errors.add(:team_id, "must be one of the match's two teams")
  end
end

# == Schema Information
#
# Table name: shootout_kicks
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  kick_order   :integer          not null
#  notes        :string
#  was_scored   :boolean          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  match_id     :bigint           not null
#  player_id    :bigint           not null
#  team_id      :bigint           not null
#
# Indexes
#
#  index_shootout_kicks_on_discarded_at         (discarded_at)
#  index_shootout_kicks_on_match_id             (match_id)
#  index_shootout_kicks_on_player_id            (player_id)
#  index_shootout_kicks_on_team_id              (team_id)
#  index_shootout_kicks_unique_order_per_match  (match_id,kick_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (team_id => teams.id)
#
