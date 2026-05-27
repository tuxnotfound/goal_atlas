class Goal < ApplicationRecord
  include Discard::Model

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  PERIODS = {
    first_half: 0,
    second_half: 1,
    extra_time_first: 2,
    extra_time_second: 3
  }.freeze

  GOAL_TYPES = {
    open_play: 0,
    penalty: 1,
    free_kick: 2,
    own_goal: 3
  }.freeze

  BODY_PARTS = {
    right_foot: 0,
    left_foot: 1,
    head: 2,
    other: 3
  }.freeze

  DATA_CONFIDENCES = {
    verified: 0,
    likely: 1,
    disputed: 2,
    estimated: 3
  }.freeze

  enum :period, PERIODS
  enum :goal_type, GOAL_TYPES
  enum :body_part, BODY_PARTS
  enum :data_confidence, DATA_CONFIDENCES, prefix: :confidence

  belongs_to :match
  belongs_to :player
  belongs_to :scoring_team, class_name: "Team"
  belongs_to :assist_player, class_name: "Player", optional: true

  has_many :goal_taggings, dependent: :destroy
  has_many :goal_tags, through: :goal_taggings
  has_many :video_links, as: :linkable, dependent: :destroy

  validates :minute, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :stoppage_time, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :goal_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :score_after_goal_home, :score_after_goal_away,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :assist_player_differs_from_scorer
  validate :scoring_team_is_in_match
  validate :own_goal_player_team_mismatch

  scope :ordered_within_match, -> {
    order(:period, :minute, :stoppage_time, :goal_order)
  }

  scope :by_team,        ->(team)       { where(scoring_team_id: team.id) }
  scope :by_player,      ->(player)     { where(player_id: player.id) }
  scope :in_tournament,  ->(tournament) { joins(:match).where(matches: { tournament_id: tournament.id }) }
  scope :against_team, ->(team) {
    joins(:match)
      .where("matches.home_team_id = :id OR matches.away_team_id = :id", id: team.id)
      .where.not(scoring_team_id: team.id)
  }

  def own_goal?
    goal_type == "own_goal"
  end

  # Compact checkmark string for the admin Goals index — Administrate
  # renders Field::Boolean as "Yes"/"No" text, so we use a String column
  # instead with an explicit ✓ glyph.
  def video
    video_links.kept.active.exists? ? "✓" : ""
  end

  # The team that did NOT score this goal (the other team in the match).
  # For own goals: this is the scorer's own nationality team.
  def opponent_team
    return nil if match.blank?
    scoring_team_id == match.home_team_id ? match.away_team : match.home_team
  end

  def slug_candidates
    return [SecureRandom.hex(4)] if player.blank? || match.blank? || opponent_team.blank?
    year = match.tournament&.year
    base = "#{player.slug}-vs-#{opponent_team.slug}-#{year}-#{minute}"
    [base, "#{base}-#{goal_order}"]
  end

  private

  def assist_player_differs_from_scorer
    return if assist_player_id.blank?
    errors.add(:assist_player_id, "cannot be the same as the scorer") if assist_player_id == player_id
  end

  def scoring_team_is_in_match
    return if match.blank? || scoring_team_id.blank?
    return if [match.home_team_id, match.away_team_id].include?(scoring_team_id)
    errors.add(:scoring_team_id, "must be one of the match's two teams")
  end

  def own_goal_player_team_mismatch
    return unless own_goal?
    return if player.blank? || player.nationality_team_id.blank?
    return if match.blank?

    if player.nationality_team_id == scoring_team_id
      errors.add(:goal_type, "own goal must credit the opposing team, not the scorer's own team")
    end
  end
end

# == Schema Information
#
# Table name: goals
#
#  id                    :bigint           not null, primary key
#  body_part             :integer
#  data_confidence       :integer          default("likely"), not null
#  description           :text
#  discarded_at          :datetime
#  goal_order            :integer          default(0), not null
#  goal_type             :integer          default("open_play"), not null
#  minute                :integer          not null
#  period                :integer          not null
#  score_after_goal_away :integer          not null
#  score_after_goal_home :integer          not null
#  slug                  :string           not null
#  source_notes          :text
#  stoppage_time         :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  assist_player_id      :bigint
#  match_id              :bigint           not null
#  player_id             :bigint           not null
#  scoring_team_id       :bigint           not null
#
# Indexes
#
#  index_goals_on_assist_player_id     (assist_player_id)
#  index_goals_on_discarded_at         (discarded_at)
#  index_goals_on_goal_type            (goal_type)
#  index_goals_on_match_and_sort_keys  (match_id,period,minute,stoppage_time,goal_order)
#  index_goals_on_match_id             (match_id)
#  index_goals_on_player_id            (player_id)
#  index_goals_on_scoring_team_id      (scoring_team_id)
#  index_goals_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (assist_player_id => players.id)
#  fk_rails_...  (match_id => matches.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (scoring_team_id => teams.id)
#
