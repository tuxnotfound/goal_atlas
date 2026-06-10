module GoalsHelper
  # Builds a URL that toggles a filter on or off.
  # Other active filters are preserved.
  def goal_filter_url(param, value)
    current = params.permit(*GoalsController::FILTER_PARAMS).to_h
    if current[param.to_s] == value.to_s
      current.delete(param.to_s)
    else
      current[param.to_s] = value.to_s
    end
    goals_path(current)
  end

  def goal_filter_active?(param, value)
    params[param.to_sym].to_s == value.to_s
  end

  def goal_filter_chip_class(active)
    base = "shrink-0 inline-block px-3.5 py-1.5 rounded-full border font-mono text-[11px] tracking-[0.2em] uppercase font-semibold transition"
    if active
      "#{base} bg-[#f0c870] text-[#fef0c8]! border-[#f0c870] shadow-md shadow-black/30 font-bold"
    else
      "#{base} bg-[rgba(253,246,220,0.06)] border-[#c89942]/45 text-[#c89942] hover:border-[#f0c870]"
    end
  end

  def any_goal_filter_active?
    GoalsController::FILTER_PARAMS.any? { |p| params[p].present? }
  end
end
