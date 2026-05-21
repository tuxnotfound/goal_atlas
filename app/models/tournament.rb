class Tournament < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :winner_team,       class_name: "Team", optional: true
  belongs_to :runner_up_team,    class_name: "Team", optional: true
  belongs_to :third_place_team,  class_name: "Team", optional: true
  belongs_to :fourth_place_team, class_name: "Team", optional: true

  has_many :matches, dependent: :restrict_with_error
  has_many :tournament_awards, dependent: :destroy

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

  # URL helpers like tournament_path(t) produce /world-cups/2022.
  def to_param
    year.to_s
  end

  private

  def end_after_start
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "must be on or after start_date") if end_date < start_date
  end
end

# == Schema Information
#
# Table name: tournaments
#
#  id                   :bigint           not null, primary key
#  discarded_at         :datetime
#  end_date             :date
#  host_countries       :string           default([]), not null, is an Array
#  name                 :string           not null
#  poster_url           :string
#  slug                 :string           not null
#  start_date           :date
#  total_goals          :integer
#  total_matches        :integer
#  year                 :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  fourth_place_team_id :bigint
#  runner_up_team_id    :bigint
#  third_place_team_id  :bigint
#  winner_team_id       :bigint
#
# Indexes
#
#  index_tournaments_on_discarded_at          (discarded_at)
#  index_tournaments_on_fourth_place_team_id  (fourth_place_team_id)
#  index_tournaments_on_name_trgm             (name) USING gin
#  index_tournaments_on_runner_up_team_id     (runner_up_team_id)
#  index_tournaments_on_slug                  (slug) UNIQUE
#  index_tournaments_on_third_place_team_id   (third_place_team_id)
#  index_tournaments_on_winner_team_id        (winner_team_id)
#  index_tournaments_on_year                  (year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fourth_place_team_id => teams.id)
#  fk_rails_...  (runner_up_team_id => teams.id)
#  fk_rails_...  (third_place_team_id => teams.id)
#  fk_rails_...  (winner_team_id => teams.id)
#
