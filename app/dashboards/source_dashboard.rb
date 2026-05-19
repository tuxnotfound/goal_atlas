require "administrate/base_dashboard"

class SourceDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    url: Field::String,
    reliability: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    notes: Field::Text,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    reliability
    url
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    url
    reliability
    notes
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    url
    reliability
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(source)
    source.name
  end
end
