require "administrate/base_dashboard"

class GoalTagDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    description: Field::Text,
    goal_taggings: Field::HasMany,
    goals: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    slug
    description
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    description
    goal_taggings
    goals
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    description
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(tag)
    tag.name
  end
end
