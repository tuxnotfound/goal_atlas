require "administrate/base_dashboard"

class MatchDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tournament: Field::BelongsTo,
    stage: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    round_label: Field::String,
    group_letter: Field::String,
    match_number: Field::Number,
    date: Field::Date,
    home_team: Field::BelongsTo,
    away_team: Field::BelongsTo,
    home_score: Field::Number,
    away_score: Field::Number,
    home_score_after_extra_time: Field::Number,
    away_score_after_extra_time: Field::Number,
    home_penalties: Field::Number,
    away_penalties: Field::Number,
    stadium: Field::BelongsTo,
    attendance: Field::Number,
    referee: Field::String,
    result_type: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    winner_team: Field::BelongsTo,
    data_confidence: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    source_notes: Field::Text,
    slug: Field::String,
    goals: Field::HasMany,
    shootout_kicks: Field::HasMany,
    video_links: Field::HasMany,
    video: Field::String.with_options(searchable: false),
    video_validated: Field::String.with_options(searchable: false),
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    date
    stage
    home_team
    away_team
    video
    video_validated
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tournament
    stage
    round_label
    group_letter
    match_number
    date
    home_team
    away_team
    home_score
    away_score
    home_score_after_extra_time
    away_score_after_extra_time
    home_penalties
    away_penalties
    stadium
    attendance
    referee
    result_type
    winner_team
    data_confidence
    source_notes
    slug
    goals
    shootout_kicks
    video_links
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    tournament
    stage
    round_label
    group_letter
    match_number
    date
    home_team
    away_team
    home_score
    away_score
    home_score_after_extra_time
    away_score_after_extra_time
    home_penalties
    away_penalties
    stadium
    attendance
    referee
    result_type
    winner_team
    data_confidence
    source_notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(match)
    "#{match.home_team&.name} #{match.home_score}-#{match.away_score} #{match.away_team&.name} (#{match.date})"
  end
end
