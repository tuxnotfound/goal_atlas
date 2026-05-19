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
