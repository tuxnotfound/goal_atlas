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

  # Matches a game by either team's name (trigram fuzzy). Most-recent first.
  # When the fuzzy team match returned more than one team, head-to-head games
  # between any two of those teams float to the top of the list — searching
  # "germ" with both Germany and West Germany returned surfaces their direct
  # meetings first, then other games involving either side.
  def matches
    return @matches ||= [] if too_short?
    @matches ||= begin
      fetched = Match.kept
                     .joins("INNER JOIN teams home_t ON home_t.id = matches.home_team_id")
                     .joins("INNER JOIN teams away_t ON away_t.id = matches.away_team_id")
                     .where("home_t.name % :q OR away_t.name % :q", q: query)
                     .includes(:home_team, :away_team, :tournament, :stadium)
                     .order(date: :desc)
                     .limit(LIMIT_PER_TYPE)
                     .to_a

      matched_team_ids = teams.map(&:id).to_set
      if matched_team_ids.size >= 2
        head_to_head, others = fetched.partition do |m|
          matched_team_ids.include?(m.home_team_id) && matched_team_ids.include?(m.away_team_id)
        end
        head_to_head + others
      else
        fetched
      end
    end
  end

  def total
    teams.size + players.size + stadiums.size + tournaments.size + matches.size
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
