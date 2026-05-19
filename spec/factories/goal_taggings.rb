FactoryBot.define do
  factory :goal_tagging do
    goal
    goal_tag
  end
end

# == Schema Information
#
# Table name: goal_taggings
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  goal_id     :bigint           not null
#  goal_tag_id :bigint           not null
#
# Indexes
#
#  index_goal_taggings_on_goal_id      (goal_id)
#  index_goal_taggings_on_goal_tag_id  (goal_tag_id)
#  index_goal_taggings_uniq            (goal_id,goal_tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (goal_id => goals.id)
#  fk_rails_...  (goal_tag_id => goal_tags.id)
#
