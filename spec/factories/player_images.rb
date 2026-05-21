FactoryBot.define do
  factory :player_image do
    player
    sequence(:url) { |n| "https://commons.wikimedia.org/file_#{n}.jpg" }
    source_url    { "https://commons.wikimedia.org/wiki/File:Example.jpg" }
    thumbnail_url { url }
    license       { "CC BY-SA 4.0" }
    license_url   { "https://creativecommons.org/licenses/by-sa/4.0/" }
    author        { "Example Author" }
    description   { "Example portrait" }
    is_default    { false }
    is_active     { true }
    position      { 0 }
    fetched_at    { Time.current }

    trait :default do
      is_default { true }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
