require 'rails_helper'

RSpec.describe PlayerImageTagging, type: :model do
  it "is valid with image + tournament" do
    expect(build(:player_image_tagging)).to be_valid
  end

  it "rejects duplicate (image, tournament) pairs" do
    tagging = create(:player_image_tagging)
    dup = build(:player_image_tagging, player_image: tagging.player_image, tournament: tagging.tournament)
    expect(dup).not_to be_valid
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
