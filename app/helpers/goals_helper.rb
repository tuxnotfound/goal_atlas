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
    base = "inline-block px-3 py-1 text-xs rounded-full transition"
    if active
      "#{base} bg-emerald-700 text-white hover:bg-emerald-800"
    else
      "#{base} bg-stone-100 text-stone-700 hover:bg-stone-200"
    end
  end

  def any_goal_filter_active?
    GoalsController::FILTER_PARAMS.any? { |p| params[p].present? }
  end
end
