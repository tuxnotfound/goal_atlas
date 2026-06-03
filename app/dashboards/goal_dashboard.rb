require "administrate/base_dashboard"

class GoalDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    match: Field::BelongsTo,
    player: Field::BelongsTo,
    scoring_team: Field::BelongsTo,
    minute: Field::Number,
    stoppage_time: Field::Number,
    period: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    goal_order: Field::Number,
    goal_type: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    body_part: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    assist_player: Field::BelongsTo,
    score_after_goal_home: Field::Number,
    score_after_goal_away: Field::Number,
    description: Field::Text,
    data_confidence: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    source_notes: Field::Text,
    slug: Field::String,
    goal_taggings: Field::HasMany,
    goal_tags: Field::HasMany,
    video_links: Field::HasMany,
    video: Field::String.with_options(searchable: false),
    video_validated: Field::String.with_options(searchable: false),
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    match
    minute
    player
    scoring_team
    goal_type
    video
    video_validated
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    match
    player
    scoring_team
    minute
    stoppage_time
    period
    goal_order
    goal_type
    body_part
    assist_player
    score_after_goal_home
    score_after_goal_away
    description
    data_confidence
    source_notes
    slug
    goal_taggings
    goal_tags
    video_links
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    match
    player
    scoring_team
    minute
    stoppage_time
    period
    goal_order
    goal_type
    body_part
    assist_player
    score_after_goal_home
    score_after_goal_away
    description
    data_confidence
    source_notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(goal)
    "#{goal.minute}' #{goal.player&.name} (#{goal.scoring_team&.fifa_code})"
  end
end
