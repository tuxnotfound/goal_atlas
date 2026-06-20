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
  # bracket cards whose team is still TBD. Examples:
  #   "1E" -> "Winner Group E"   "2B" -> "Runner-up Group B"
  #   "3ABCDF" -> "3rd: A/B/C/D/F"  "W74" -> "Winner Match 74"  "L101" -> "Loser Match 101"
  def knockout_source_label(code)
    case code.to_s
    when /\A1([A-L])\z/      then "Winner Group #{$1}"
    when /\A2([A-L])\z/      then "Runner-up Group #{$1}"
    when /\A3([A-L]{2,})\z/  then "3rd: #{$1.chars.join('/')}"
    when /\AW(\d+)\z/        then "Winner Match #{$1}"
    when /\AL(\d+)\z/        then "Loser Match #{$1}"
    else                          "TBD"
    end
  end
end
