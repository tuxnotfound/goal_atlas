FactoryBot.define do
  factory :goal_tag do
    sequence(:name) { |n| "Tag #{n}" }
    slug { nil }
    description { nil }

    trait :bicycle_kick do
      name { "Bicycle Kick" }
      description { "Overhead/scissor kick goal." }
    end

    trait :solo_run do
      name { "Solo Run" }
      description { "Goal where the scorer dribbled past multiple defenders before scoring." }
    end

    trait :long_range do
      name { "Long Range" }
      description { "Goal scored from outside the penalty area." }
    end
  end
end

# == Schema Information
#
# Table name: goal_tags
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_goal_tags_on_name  (name) UNIQUE
#  index_goal_tags_on_slug  (slug) UNIQUE
#
