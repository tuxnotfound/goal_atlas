require "administrate/base_dashboard"

class TournamentAwardDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    tournament: Field::BelongsTo,
    player: Field::BelongsTo,
    award_type: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    notes: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    tournament
    award_type
    player
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    tournament
    award_type
    player
    notes
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    tournament
    award_type
    player
    notes
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(award)
    "#{award.tournament&.year} #{award.award_type&.titleize} — #{award.player&.name}"
  end
end
