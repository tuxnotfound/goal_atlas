class TournamentAward < ApplicationRecord
  AWARD_TYPES = {
    golden_ball: 0,
    silver_ball: 1,
    bronze_ball: 2,
    golden_boot: 3,
    silver_boot: 4,
    bronze_boot: 5,
    golden_glove: 6,
    best_young_player: 7
  }.freeze

  enum :award_type, AWARD_TYPES

  belongs_to :tournament
  belongs_to :player

  validates :award_type, presence: true
  validates :player_id, uniqueness: { scope: [:tournament_id, :award_type] }

  scope :ordered, -> { order(:award_type) }

  def display_name
    award_type.to_s.titleize
  end
end
