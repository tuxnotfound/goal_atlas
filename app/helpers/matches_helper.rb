module MatchesHelper
  # Formats the clock time of a goal: e.g. "23'", "90+11'", "117+3' ET"
  def goal_minute_label(goal)
    base = goal.stoppage_time ? "#{goal.minute}+#{goal.stoppage_time}'" : "#{goal.minute}'"
    case goal.period
    when "extra_time_first", "extra_time_second"
      "#{base} ET"
    else
      base
    end
  end

  # Short result label: e.g. "AET", "Pens", or nil for regulation
  def result_type_short(match)
    case match.result_type
    when "after_extra_time"  then "AET"
    when "after_penalties"   then "Pens"
    when "abandoned"         then "Abandoned"
    when "replay_required"   then "Replay"
    when "walkover"          then "Walkover"
    end
  end

  # Stage label: e.g. "Quarter-final" instead of "quarter_final"
  def stage_label(match)
    match.stage.to_s.humanize.gsub("Round of", "Round of")
  end

  # Humanizes a knockout placeholder source code into a short slot label, for
  # bracket/match cards whose team is still TBD. Delegates to the model so the
  # mapping has one home. Examples: "1E" -> "Winner Group E", "W74" -> "Winner Match 74".
  def knockout_source_label(code)
    Match.humanize_source_label(code)
  end
end
