FactoryBot.define do
  factory :tournament_award do
    tournament
    player
    award_type { :golden_ball }
    notes { nil }
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
