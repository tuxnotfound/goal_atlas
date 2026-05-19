FactoryBot.define do
  factory :stadium do
    sequence(:name) { |n| "Stadium #{n}" }
    slug { nil }
    city { "Doha" }
    country { "Qatar" }
    country_code { "QA" }
    latitude { 25.2769 }
    longitude { 51.5212 }
    current_capacity { 50_000 }
    notes { nil }
    discarded_at { nil }

    trait :lusail do
      name { "Lusail Iconic Stadium" }
      city { "Lusail" }
      country { "Qatar" }
      country_code { "QA" }
      latitude { 25.4242 }
      longitude { 51.4906 }
      current_capacity { 88_966 }
    end
  end
end
