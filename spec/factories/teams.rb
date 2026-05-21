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

# == Schema Information
#
# Table name: teams
#
#  id                :bigint           not null, primary key
#  active_from       :integer
#  active_until      :integer
#  confederation     :integer          not null
#  country_code      :string           not null
#  discarded_at      :datetime
#  fifa_code         :string
#  flag_emoji        :string
#  name              :string           not null
#  slug              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  successor_team_id :bigint
#
# Indexes
#
#  index_teams_on_country_code       (country_code)
#  index_teams_on_discarded_at       (discarded_at)
#  index_teams_on_name               (name)
#  index_teams_on_name_trgm          (name) USING gin
#  index_teams_on_slug               (slug) UNIQUE
#  index_teams_on_successor_team_id  (successor_team_id)
#
# Foreign Keys
#
#  fk_rails_...  (successor_team_id => teams.id)
#
