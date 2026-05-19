FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    slug { nil } # friendly_id generates this from name
    country_code { "BR" }
    fifa_code { "BRA" }
    flag_emoji { "🇧🇷" }
    confederation { :conmebol }
    active_from { nil }
    active_until { nil }
    successor_team { nil }
    discarded_at { nil }

    trait :west_germany do
      name { "West Germany" }
      country_code { "DE" }
      fifa_code { "FRG" }
      confederation { :uefa }
      active_from { 1908 }
      active_until { 1990 }
    end

    trait :germany do
      name { "Germany" }
      country_code { "DE" }
      fifa_code { "GER" }
      confederation { :uefa }
    end
  end
end
