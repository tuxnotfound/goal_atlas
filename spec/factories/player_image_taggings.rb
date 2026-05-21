FactoryBot.define do
  factory :player_image_tagging do
    player_image
    tournament
  end
end

# == Schema Information
#
# Table name: player_image_taggings
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  player_image_id :bigint           not null
#  tournament_id   :bigint           not null
#
# Indexes
#
#  index_player_image_taggings_on_player_image_id  (player_image_id)
#  index_player_image_taggings_on_tournament_id    (tournament_id)
#  index_player_image_taggings_unique              (player_image_id,tournament_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (player_image_id => player_images.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
