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

# == Schema Information
#
# Table name: tournament_awards
#
#  id            :bigint           not null, primary key
#  award_type    :integer          not null
#  notes         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player_id     :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_tournament_awards_on_award_type     (award_type)
#  index_tournament_awards_on_player_id      (player_id)
#  index_tournament_awards_on_tournament_id  (tournament_id)
#  index_tournament_awards_uniq              (tournament_id,award_type,player_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
