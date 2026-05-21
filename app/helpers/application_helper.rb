module ApplicationHelper
  include Pagy::Frontend

  # First letter of the first two name tokens, e.g.:
  #   "Diego Maradona"  → "DM"
  #   "Pelé"            → "P"
  #   "Hong Myung-bo"   → "HM"
  def avatar_initials(name)
    return "?" if name.blank?
    name.split.first(2).map { |t| t.chars.first }.join.upcase
  end
end
