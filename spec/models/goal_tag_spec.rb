require 'rails_helper'

RSpec.describe GoalTag, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:goal_tag)).to be_valid
    end

    it "requires a name" do
      expect(build(:goal_tag, name: nil)).not_to be_valid
    end

    it "enforces unique name" do
      create(:goal_tag, :bicycle_kick)
      expect(build(:goal_tag, :bicycle_kick)).not_to be_valid
    end
  end

  describe "slug" do
    it "auto-generates from name" do
      tag = create(:goal_tag, :bicycle_kick)
      expect(tag.slug).to eq("bicycle-kick")
    end
  end

  describe "associations" do
    it "links to goals through goal_taggings" do
      tag = create(:goal_tag, :solo_run)
      goal = create(:goal)
      create(:goal_tagging, goal: goal, goal_tag: tag)

      expect(tag.goals).to include(goal)
      expect(goal.goal_tags).to include(tag)
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
