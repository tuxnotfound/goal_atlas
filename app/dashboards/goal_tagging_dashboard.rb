require "administrate/base_dashboard"

class GoalTaggingDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    goal: Field::BelongsTo,
    goal_tag: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    goal
    goal_tag
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    goal
    goal_tag
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    goal
    goal_tag
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(tagging)
    "Goal ##{tagging.goal_id} → #{tagging.goal_tag&.name}"
  end
end
