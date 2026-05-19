require "administrate/base_dashboard"

class TournamentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    year: Field::Number,
    name: Field::String,
    slug: Field::String,
    host_countries: Field::String.with_options(searchable: false),
    start_date: Field::Date,
    end_date: Field::Date,
    winner_team: Field::BelongsTo,
    runner_up_team: Field::BelongsTo,
    third_place_team: Field::BelongsTo,
    fourth_place_team: Field::BelongsTo,
    total_matches: Field::Number,
    total_goals: Field::Number,
    poster_url: Field::String,
    discarded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    year
    name
    winner_team
    total_goals
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    year
    name
    slug
    host_countries
    start_date
    end_date
    winner_team
    runner_up_team
    third_place_team
    fourth_place_team
    total_matches
    total_goals
    poster_url
    discarded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    year
    name
    host_countries
    start_date
    end_date
    winner_team
    runner_up_team
    third_place_team
    fourth_place_team
    total_matches
    total_goals
    poster_url
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(tournament)
    tournament.name
  end
end
