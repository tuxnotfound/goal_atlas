require "administrate/base_dashboard"

class StadiumDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    city: Field::String,
    country: Field::String,
    country_code: Field::String,
    latitude: Field::Number.with_options(decimals: 6),
    longitude: Field::Number.with_options(decimals: 6),
    current_capacity: Field::Number,
    notes: Field::Text,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    city
    country
    current_capacity
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    city
    country
    country_code
    latitude
    longitude
    current_capacity
    notes
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    city
    country
    country_code
    latitude
    longitude
    current_capacity
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(stadium)
    "#{stadium.name} (#{stadium.city})"
  end
end
