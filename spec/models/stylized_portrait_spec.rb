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
