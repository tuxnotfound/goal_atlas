FactoryBot.define do
  factory :player do
    sequence(:name) { |n| "Player #{n}" }
    slug { nil }
    name_local { nil }
    birth_date { nil }
    nationality_team { nil }
    position { nil }
    discarded_at { nil }

    trait :messi do
      name { "Lionel Messi" }
      birth_date { Date.new(1987, 6, 24) }
      position { :forward }
    end

    trait :mbappe do
      name { "Kylian Mbappé" }
      birth_date { Date.new(1998, 12, 20) }
      position { :forward }
    end
  end
end
