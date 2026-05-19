require "administrate/base_dashboard"

class PlayerDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    name_local: Field::String,
    birth_date: Field::Date,
    nationality_team: Field::BelongsTo,
    position: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    goals: Field::HasMany,
    assisted_goals: Field::HasMany,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    nationality_team
    position
    birth_date
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    name_local
    birth_date
    nationality_team
    position
    goals
    assisted_goals
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    name_local
    birth_date
    nationality_team
    position
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(player)
    player.name
  end
end
