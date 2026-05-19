FactoryBot.define do
  factory :tournament do
    sequence(:year) { |n| 1930 + (n * 4) }
    slug { nil }
    name { "FIFA World Cup #{year}" }
    host_countries { ["Qatar"] }
    start_date { nil }
    end_date   { nil }
    total_matches { 64 }
    total_goals { 172 }
    poster_url { nil }
    discarded_at { nil }

    trait :wc_2022 do
      year { 2022 }
      name { "FIFA World Cup 2022" }
      host_countries { ["Qatar"] }
      start_date { Date.new(2022, 11, 20) }
      end_date { Date.new(2022, 12, 18) }
      total_matches { 64 }
      total_goals { 172 }
    end

    trait :wc_2026_joint_host do
      year { 2026 }
      name { "FIFA World Cup 2026" }
      host_countries { ["Mexico", "United States", "Canada"] }
      start_date { Date.new(2026, 6, 11) }
      end_date { Date.new(2026, 7, 19) }
    end
  end
end
