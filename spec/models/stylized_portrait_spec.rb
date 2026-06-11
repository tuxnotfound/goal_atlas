require 'rails_helper'

RSpec.describe StylizedPortrait, type: :model do
  describe "#public_url" do
    it "returns the portraits route URL for the stored basename" do
      portrait = build(:stylized_portrait, file_path: "lionel-messi_1700000000.png")
      expect(portrait.public_url).to eq("/portraits/lionel-messi_1700000000.png")
    end
  end

  describe "#absolute_path" do
    it "joins the storage dir with the stored basename" do
      portrait = build(:stylized_portrait, file_path: "foo.png")
      expect(portrait.absolute_path.to_s).to end_with("storage/stylized_portraits/foo.png")
    end
  end

  describe "#file_exists?" do
    it "returns false when the file is not on disk" do
      portrait = build(:stylized_portrait, file_path: "definitely-missing.png")
      expect(portrait.file_exists?).to be(false)
    end
  end
end

# == Schema Information
#
# Table name: stylized_portraits
#
#  id                     :bigint           not null, primary key
#  file_path              :string           not null
#  generated_at           :datetime         not null
#  is_selected            :boolean          default(FALSE), not null
#  model                  :string
#  prompt                 :text
#  quality                :string
#  size                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  player_id              :bigint           not null
#  source_player_image_id :bigint
#
# Indexes
#
#  index_stylized_portraits_on_player_id               (player_id)
#  index_stylized_portraits_on_source_player_image_id  (source_player_image_id)
#  index_stylized_portraits_one_selected_per_player    (player_id,is_selected) UNIQUE WHERE (is_selected = true)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (source_player_image_id => player_images.id)
#
