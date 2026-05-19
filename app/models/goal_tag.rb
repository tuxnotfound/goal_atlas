class GoalTag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :goal_taggings, dependent: :destroy
  has_many :goals, through: :goal_taggings

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
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
