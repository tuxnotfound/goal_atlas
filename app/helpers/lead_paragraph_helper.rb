module LeadParagraphHelper
  def match_lead(match)
    date_str = match.date.strftime("%-d %B %Y")
    venue    = venue_phrase(match)
    stage    = match.stage.to_s.humanize
    home     = team_link(match.home_team)
    away     = team_link(match.away_team)
    tournament_name = link_to(match.tournament.name, tournament_path(match.tournament),
                              class: "text-[#1c5c3f] underline decoration-[#c89942]/50 hover:decoration-[#c89942] underline-offset-2 transition")
    context  = "in the #{stage} of the #{tournament_name}"

    final_home, final_away, aet = final_scores(match)

    body =
      if match.scheduled?
        "#{home} are scheduled to face #{away} on #{date_str}#{venue} #{context}."
      elsif match.home_penalties
        score = "#{final_home}–#{final_away}"
        pens  = penalty_phrase(match)
        "On #{date_str}, #{home} and #{away} drew #{score}#{aet ? ' after extra time' : ''}#{venue} #{context}; #{pens}."
      elsif match.winner_team_id
        winner = match.winner_team_id == match.home_team_id ? home : away
        loser  = match.winner_team_id == match.home_team_id ? away : home
        winner_score = match.winner_team_id == match.home_team_id ? final_home : final_away
        loser_score  = match.winner_team_id == match.home_team_id ? final_away : final_home
        score = "#{winner_score}–#{loser_score}"
        "On #{date_str}, #{winner} beat #{loser} #{score}#{aet ? ' after extra time' : ''}#{venue} #{context}."
      else
        score = "#{final_home}–#{final_away}"
        "On #{date_str}, #{home} drew #{score} with #{away}#{venue} #{context}."
      end

    sanitize(body, tags: %w[a], attributes: %w[href class])
  end

  def tournament_lead(tournament)
    hosts = tournament.host_countries.to_sentence
    date_range =
      if tournament.start_date && tournament.end_date
        "from #{tournament.start_date.strftime('%-d %B')} to #{tournament.end_date.strftime('%-d %B %Y')}"
      else
        "in #{tournament.year}"
      end

    pieces = ["The #{tournament.name} was hosted by #{hosts} #{date_range}."]

    if tournament.winner_team
      winner = team_link(tournament.winner_team)
      if tournament.runner_up_team
        runner = team_link(tournament.runner_up_team)
        pieces << "#{winner} won the tournament, beating #{runner} in the final."
      else
        pieces << "#{winner} won the tournament."
      end
    end

    if (golden_boot = tournament.tournament_awards.where(award_type: :golden_boot).first)
      pieces << "#{player_link(golden_boot.player)} won the Golden Boot."
    end

    sanitize(pieces.join(" "), tags: %w[a], attributes: %w[href class])
  end

  def player_lead(player, tournament_records:, goals:)
    return "" if tournament_records.empty? && goals.empty?

    years = tournament_records.map { |r| r.tournament.year }.sort
    year_phrase =
      if years.size == 1
        "the #{years.first} FIFA World Cup"
      elsif years.size == 2
        "the #{years.first} and #{years.last} FIFA World Cups"
      else
        "#{years.size} FIFA World Cups between #{years.first} and #{years.last}"
      end

    nationality = player.nationality_team ? " for #{team_link(player.nationality_team)}" : ""
    goal_count  = goals.size
    goal_phrase = goal_count.positive? ? ", scoring #{pluralize(goal_count, 'goal')}" : ""

    pieces = ["#{player.name} played in #{year_phrase}#{nationality}#{goal_phrase}."]

    champions = if player.nationality_team_id
      tournament_records.select { |r| r.tournament.winner_team_id == player.nationality_team_id }
    else
      []
    end
    if champions.any?
      champion_years = champions.map { |r| r.tournament.year }.sort
      pieces << "He won the World Cup in #{champion_years.to_sentence}."
    end

    sanitize(pieces.join(" "), tags: %w[a], attributes: %w[href class])
  end

  private

  def team_link(team)
    link_to(team.name, team_path(team), class: "text-[#1c5c3f] underline decoration-[#c89942]/50 hover:decoration-[#c89942] underline-offset-2 transition")
  end

  def player_link(player)
    link_to(player.name, player_path(player), class: "text-[#1c5c3f] underline decoration-[#c89942]/50 hover:decoration-[#c89942] underline-offset-2 transition")
  end

  def venue_phrase(match)
    return "" unless match.stadium
    " at #{match.stadium.name}, #{match.stadium.city}"
  end

  def final_scores(match)
    if match.home_score_after_extra_time
      [match.home_score_after_extra_time, match.away_score_after_extra_time, true]
    else
      [match.home_score, match.away_score, false]
    end
  end

  def penalty_phrase(match)
    winner = match.winner_team_id == match.home_team_id ? match.home_team : match.away_team
    winner_pens = match.winner_team_id == match.home_team_id ? match.home_penalties : match.away_penalties
    loser_pens  = match.winner_team_id == match.home_team_id ? match.away_penalties : match.home_penalties
    "#{team_link(winner)} won #{winner_pens}–#{loser_pens} on penalties"
  end
end
