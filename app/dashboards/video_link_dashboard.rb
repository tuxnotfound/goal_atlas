require "administrate/base_dashboard"

class VideoLinkDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    linkable: Field::Polymorphic,
    source: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    url: Field::String,
    starts_at_seconds: Field::Number,
    ends_at_seconds: Field::Number,
    embed_allowed: Field::Boolean,
    language: Field::String,
    confidence: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    last_checked_at: Field::DateTime,
    is_active: Field::Boolean,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    linkable
    source
    url
    is_active
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    linkable
    source
    url
    starts_at_seconds
    ends_at_seconds
    embed_allowed
    language
    confidence
    last_checked_at
    is_active
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    linkable
    source
    url
    starts_at_seconds
    ends_at_seconds
    embed_allowed
    language
    confidence
    last_checked_at
    is_active
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(link)
    "#{link.source} → #{link.url}"
  end
end
