FactoryBot.define do
  factory :tournament_participation do
    player
    tournament
  end
end

# == Schema Information
#
# Table name: tournament_participations
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player_id     :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_tournament_participations_on_tournament_id  (tournament_id)
#  index_tournament_participations_uniq              (player_id,tournament_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
