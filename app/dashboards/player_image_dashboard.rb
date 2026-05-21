require "administrate/base_dashboard"

class PlayerImageDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    player: Field::BelongsTo,
    url: Field::String,
    source_url: Field::String,
    thumbnail_url: Field::String,
    license: Field::String,
    license_url: Field::String,
    author: Field::String,
    description: Field::Text,
    is_default: Field::Boolean,
    position: Field::Number,
    is_active: Field::Boolean,
    fetched_at: Field::DateTime,
    notes: Field::Text,
    tournaments: Field::HasMany,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    player
    license
    author
    is_default
    is_active
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    player
    url
    source_url
    license
    license_url
    author
    description
    is_default
    is_active
    position
    tournaments
    fetched_at
    notes
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    player
    url
    source_url
    thumbnail_url
    license
    license_url
    author
    description
    is_default
    is_active
    position
    tournaments
    notes
  ].freeze

  COLLECTION_FILTERS = {
    default: ->(resources) { resources.default },
    inactive: ->(resources) { resources.where(is_active: false) },
    untagged: ->(resources) { resources.left_outer_joins(:player_image_taggings).where(player_image_taggings: { id: nil }) }
  }.freeze

  def display_resource(image)
    "#{image.player&.name} — image ##{image.id}"
  end
end
