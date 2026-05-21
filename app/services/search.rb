# Cross-entity fuzzy search using PostgreSQL pg_trgm.
#
# Returns top hits for each indexed type — teams, players, tournaments,
# stadiums — ordered by trigram similarity to the query. Use Search#empty?
# to render a "no results" view.
#
#   results = Search.new("maradon")
#   results.players  # => [Diego Maradona, ...]
#   results.empty?   # => false
class Search
  LIMIT_PER_TYPE = 15
  MIN_QUERY_LENGTH = 2

  attr_reader :query

  def initialize(query)
    @query = query.to_s.strip
  end

  def teams
    @teams ||= fuzzy(Team.kept).limit(LIMIT_PER_TYPE).to_a
  end

  def players
    @players ||= fuzzy(Player.kept).includes(:nationality_team).limit(LIMIT_PER_TYPE).to_a
  end

  def stadiums
    @stadiums ||= fuzzy(Stadium.kept).limit(LIMIT_PER_TYPE).to_a
  end

  # Tournaments are few enough that a plain ILIKE plus year match is more useful
  # than trigram similarity ("2022" wouldn't fuzzy-match "FIFA World Cup 2022").
  def tournaments
    return @tournaments ||= [] if too_short?
    @tournaments ||=
      Tournament.kept.where(
        "name ILIKE :pat OR year::text = :exact",
        pat: "%#{sanitize_like(query)}%", exact: query
      ).ordered_by_year.limit(LIMIT_PER_TYPE).to_a
  end

  def total
    teams.size + players.size + stadiums.size + tournaments.size
  end

  def empty?
    total.zero?
  end

  def too_short?
    query.length < MIN_QUERY_LENGTH
  end

  private

  def fuzzy(scope)
    return scope.none if too_short?
    sanitized = ActiveRecord::Base.connection.quote(query)
    scope.where("name % ?", query)
         .order(Arel.sql("similarity(name, #{sanitized}) DESC, name ASC"))
  end

  def sanitize_like(value)
    value.gsub(/[\\%_]/) { |c| "\\#{c}" }
  end
end
