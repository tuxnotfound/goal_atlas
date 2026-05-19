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

# == Schema Information
#
# Table name: players
#
#  id                  :bigint           not null, primary key
#  birth_date          :date
#  discarded_at        :datetime
#  name                :string           not null
#  name_local          :string
#  position            :integer
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  nationality_team_id :bigint
#
# Indexes
#
#  index_players_on_discarded_at         (discarded_at)
#  index_players_on_name                 (name)
#  index_players_on_nationality_team_id  (nationality_team_id)
#  index_players_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (nationality_team_id => teams.id)
#
