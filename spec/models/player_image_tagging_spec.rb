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
