require 'rails_helper'

RSpec.describe VideoLink, type: :model do
  describe "validations" do
    it "is valid with minimal attributes (attached to a Match)" do
      expect(build(:video_link)).to be_valid
    end

    it "is valid attached to a Goal" do
      expect(build(:video_link, :for_goal)).to be_valid
    end

    it "rejects an unsupported linkable_type" do
      stadium = create(:stadium)
      link = build(:video_link, linkable: stadium)
      expect(link).not_to be_valid
      expect(link.errors[:linkable_type]).to be_present
    end

    it "requires a URL" do
      expect(build(:video_link, url: nil)).not_to be_valid
    end

    it "rejects malformed URLs" do
      expect(build(:video_link, url: "not a url")).not_to be_valid
    end

    it "rejects ends_at_seconds <= starts_at_seconds" do
      expect(build(:video_link, starts_at_seconds: 60, ends_at_seconds: 60)).not_to be_valid
      expect(build(:video_link, starts_at_seconds: 60, ends_at_seconds: 30)).not_to be_valid
      expect(build(:video_link, starts_at_seconds: 60, ends_at_seconds: 90)).to be_valid
    end
  end

  describe "scopes" do
    let!(:active_link)   { create(:video_link, is_active: true) }
    let!(:inactive_link) { create(:video_link, is_active: false) }
    let!(:embeddable)    { create(:video_link, :fifa_plus) }
    let!(:non_embeddable) { create(:video_link, embed_allowed: false) }

    it "scopes .active" do
      expect(VideoLink.active).to include(active_link, embeddable)
      expect(VideoLink.active).not_to include(inactive_link)
    end

    it "scopes .embeddable" do
      expect(VideoLink.embeddable).to include(embeddable)
      expect(VideoLink.embeddable).not_to include(non_embeddable)
    end
  end

  describe "source enum" do
    it "exposes the five sources" do
      expect(VideoLink.sources.keys).to contain_exactly(
        "fifa_plus", "youtube_official", "archive_org", "broadcaster", "other"
      )
    end
  end

  describe "discard" do
    it "soft-deletes" do
      link = create(:video_link)
      link.discard
      expect(VideoLink.kept).not_to include(link)
    end
  end
end

# == Schema Information
#
# Table name: video_links
#
#  id                     :bigint           not null, primary key
#  confidence             :integer          default("likely"), not null
#  discarded_at           :datetime
#  embed_allowed          :boolean          default(FALSE), not null
#  ends_at_seconds        :integer
#  is_active              :boolean          default(TRUE), not null
#  language               :string
#  last_checked_at        :datetime
#  linkable_type          :string           not null
#  source                 :integer          not null
#  starts_at_seconds      :integer
#  url                    :string           not null
#  video_duration_seconds :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  linkable_id            :bigint           not null
#
# Indexes
#
#  index_video_links_on_discarded_at  (discarded_at)
#  index_video_links_on_is_active     (is_active)
#  index_video_links_on_linkable      (linkable_type,linkable_id)
#  index_video_links_on_source        (source)
#
