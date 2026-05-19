require "administrate/base_dashboard"

class TeamDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    country_code: Field::String,
    fifa_code: Field::String,
    flag_emoji: Field::String,
    confederation: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    active_from: Field::Number,
    active_until: Field::Number,
    successor_team: Field::BelongsTo,
    predecessor_teams: Field::HasMany,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    fifa_code
    confederation
    country_code
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    country_code
    fifa_code
    flag_emoji
    confederation
    active_from
    active_until
    successor_team
    predecessor_teams
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    country_code
    fifa_code
    flag_emoji
    confederation
    active_from
    active_until
    successor_team
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(team)
    [team.flag_emoji, team.name].compact.join(" ")
  end
end
