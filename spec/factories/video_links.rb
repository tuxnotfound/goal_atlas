FactoryBot.define do
  factory :video_link do
    linkable factory: :match
    source { :youtube_official }
    sequence(:url) { |n| "https://example.com/video/#{n}" }
    starts_at_seconds { nil }
    ends_at_seconds { nil }
    embed_allowed { false }
    language { nil }
    confidence { :likely }
    last_checked_at { nil }
    is_active { true }
    discarded_at { nil }

    trait :for_goal do
      linkable factory: :goal
    end

    trait :fifa_plus do
      source { :fifa_plus }
      url { "https://fifa.com/fifaplus/video/example" }
      embed_allowed { true }
      confidence { :verified }
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
