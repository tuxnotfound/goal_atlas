FactoryBot.define do
  factory :source do
    sequence(:name) { |n| "Source #{n}" }
    url { "https://example.com" }
    reliability { :medium }
    notes { nil }
    discarded_at { nil }

    trait :rsssf do
      name { "RSSSF" }
      url { "https://rsssf.org" }
      reliability { :high }
      notes { "Rec.Sport.Soccer Statistics Foundation - reference historical archive." }
    end

    trait :fifa_official do
      name { "FIFA Official" }
      url { "https://fifa.com" }
      reliability { :official }
    end

    trait :wikipedia do
      name { "Wikipedia (EN)" }
      url { "https://en.wikipedia.org" }
      reliability { :medium }
    end
  end
end

# == Schema Information
#
# Table name: sources
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  notes        :text
#  reliability  :integer          not null
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_sources_on_discarded_at  (discarded_at)
#  index_sources_on_name          (name) UNIQUE
#
