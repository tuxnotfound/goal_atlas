class Tournament < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :winner_team,       class_name: "Team", optional: true
  belongs_to :runner_up_team,    class_name: "Team", optional: true
  belongs_to :third_place_team,  class_name: "Team", optional: true
  belongs_to :fourth_place_team, class_name: "Team", optional: true

  validates :year, presence: true, uniqueness: true,
                   numericality: { only_integer: true, greater_than: 1900, less_than: 2100 }
  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validate  :end_after_start

  scope :ordered_by_year, -> { order(year: :asc) }

  def slug_candidates
    ["world-cup-#{year}", "wc-#{year}"]
  end

  def should_generate_new_friendly_id?
    year_changed? || super
  end

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "must be on or after start_date") if end_date < start_date
  end
end
