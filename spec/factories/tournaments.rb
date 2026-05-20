FactoryBot.define do
  factory :tournament do
    sequence(:year) { |n| 1930 + (n % 40) }
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

# == Schema Information
#
# Table name: tournaments
#
#  id                   :bigint           not null, primary key
#  discarded_at         :datetime
#  end_date             :date
#  host_countries       :string           default([]), not null, is an Array
#  name                 :string           not null
#  poster_url           :string
#  slug                 :string           not null
#  start_date           :date
#  total_goals          :integer
#  total_matches        :integer
#  year                 :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  fourth_place_team_id :bigint
#  runner_up_team_id    :bigint
#  third_place_team_id  :bigint
#  winner_team_id       :bigint
#
# Indexes
#
#  index_tournaments_on_discarded_at          (discarded_at)
#  index_tournaments_on_fourth_place_team_id  (fourth_place_team_id)
#  index_tournaments_on_runner_up_team_id     (runner_up_team_id)
#  index_tournaments_on_slug                  (slug) UNIQUE
#  index_tournaments_on_third_place_team_id   (third_place_team_id)
#  index_tournaments_on_winner_team_id        (winner_team_id)
#  index_tournaments_on_year                  (year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fourth_place_team_id => teams.id)
#  fk_rails_...  (runner_up_team_id => teams.id)
#  fk_rails_...  (third_place_team_id => teams.id)
#  fk_rails_...  (winner_team_id => teams.id)
#
