require "administrate/base_dashboard"

class ShootoutKickDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    match: Field::BelongsTo,
    team: Field::BelongsTo,
    player: Field::BelongsTo,
    kick_order: Field::Number,
    was_scored: Field::Boolean,
    notes: Field::String,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    match
    kick_order
    player
    was_scored
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    match
    team
    player
    kick_order
    was_scored
    notes
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    match
    team
    player
    kick_order
    was_scored
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(kick)
    "#{kick.kick_order}. #{kick.player&.name} (#{kick.team&.fifa_code})"
  end
end
