class Match < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  STAGES = {
    group_stage: 0,
    second_group_stage: 1,
    round_of_32: 2,
    round_of_16: 3,
    quarter_final: 4,
    semi_final: 5,
    third_place_playoff: 6,
    final: 7
  }.freeze

  RESULT_TYPES = {
    regulation: 0,
    after_extra_time: 1,
    after_penalties: 2,
    abandoned: 3,
    replay_required: 4,
    walkover: 5
  }.freeze

  DATA_CONFIDENCES = {
    verified: 0,
    likely: 1,
    disputed: 2,
    estimated: 3
  }.freeze

  enum :stage, STAGES
  enum :result_type, RESULT_TYPES
  enum :data_confidence, DATA_CONFIDENCES, prefix: :confidence

  belongs_to :tournament
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :stadium, optional: true
  belongs_to :winner_team, class_name: "Team", optional: true

  validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :date, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :distinct_teams
  validate :winner_is_one_of_the_teams

  scope :ordered_by_date, -> { order(date: :asc, id: :asc) }

  def slug_candidates
    base = "#{home_team&.slug}-vs-#{away_team&.slug}-#{date&.year}"
    base = base.sub(/-+/, "-")
    [base, "#{base}-#{stage}"]
  end

  private

  def distinct_teams
    return if home_team_id.blank? || away_team_id.blank?
    errors.add(:away_team_id, "must differ from home team") if home_team_id == away_team_id
  end

  def winner_is_one_of_the_teams
    return if winner_team_id.blank?
    return if [home_team_id, away_team_id].include?(winner_team_id)
    errors.add(:winner_team_id, "must be one of the two playing teams")
  end
end

# == Schema Information
#
# Table name: matches
#
#  id                          :bigint           not null, primary key
#  attendance                  :integer
#  away_penalties              :integer
#  away_score                  :integer          default(0), not null
#  away_score_after_extra_time :integer
#  data_confidence             :integer          default("likely"), not null
#  date                        :date             not null
#  discarded_at                :datetime
#  group_letter                :string
#  home_penalties              :integer
#  home_score                  :integer          default(0), not null
#  home_score_after_extra_time :integer
#  match_number                :integer
#  referee                     :string
#  result_type                 :integer          default("regulation"), not null
#  round_label                 :string
#  slug                        :string           not null
#  source_notes                :text
#  stage                       :integer          not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  away_team_id                :bigint           not null
#  home_team_id                :bigint           not null
#  stadium_id                  :bigint
#  tournament_id               :bigint           not null
#  winner_team_id              :bigint
#
# Indexes
#
#  index_matches_on_away_team_id                    (away_team_id)
#  index_matches_on_date                            (date)
#  index_matches_on_discarded_at                    (discarded_at)
#  index_matches_on_home_team_id                    (home_team_id)
#  index_matches_on_slug                            (slug) UNIQUE
#  index_matches_on_stadium_id                      (stadium_id)
#  index_matches_on_stage                           (stage)
#  index_matches_on_tournament_id                   (tournament_id)
#  index_matches_on_tournament_id_and_match_number  (tournament_id,match_number)
#  index_matches_on_winner_team_id                  (winner_team_id)
#
# Foreign Keys
#
#  fk_rails_...  (away_team_id => teams.id)
#  fk_rails_...  (home_team_id => teams.id)
#  fk_rails_...  (stadium_id => stadiums.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_team_id => teams.id)
#
