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

# == Schema Information
#
# Table name: stadiums
#
#  id               :bigint           not null, primary key
#  city             :string           not null
#  country          :string           not null
#  country_code     :string
#  current_capacity :integer
#  discarded_at     :datetime
#  latitude         :decimal(9, 6)
#  longitude        :decimal(9, 6)
#  name             :string           not null
#  notes            :text
#  slug             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_stadiums_on_city          (city)
#  index_stadiums_on_country_code  (country_code)
#  index_stadiums_on_discarded_at  (discarded_at)
#  index_stadiums_on_name          (name)
#  index_stadiums_on_slug          (slug) UNIQUE
#
