require 'rails_helper'

RSpec.describe GoalTagging, type: :model do
  describe "validations" do
    it "is valid with both goal and goal_tag" do
      expect(build(:goal_tagging)).to be_valid
    end

    it "rejects a duplicate (goal, goal_tag) pair" do
      tag = create(:goal_tag, :bicycle_kick)
      goal = create(:goal)
      create(:goal_tagging, goal: goal, goal_tag: tag)

      duplicate = build(:goal_tagging, goal: goal, goal_tag: tag)
      expect(duplicate).not_to be_valid
    end
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
