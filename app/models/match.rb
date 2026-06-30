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
    walkover: 5,
    scheduled: 6
  }.freeze

  DATA_CONFIDENCES = {
    verified: 0,
    likely: 1,
    disputed: 2,
    estimated: 3
  }.freeze

  # Knockout rounds whose matches may be seeded as placeholders before their
  # teams are known (the WC2026 bracket): such rows carry source labels instead
  # of teams. See #knockout_placeholder?.
  KNOCKOUT_STAGES = %w[round_of_32 round_of_16 quarter_final semi_final third_place_playoff final].freeze

  enum :stage, STAGES
  enum :result_type, RESULT_TYPES
  enum :data_confidence, DATA_CONFIDENCES, prefix: :confidence

  belongs_to :tournament
  belongs_to :home_team, class_name: "Team", optional: true
  belongs_to :away_team, class_name: "Team", optional: true
  belongs_to :stadium, optional: true
  belongs_to :winner_team, class_name: "Team", optional: true
  belongs_to :replay_of_match, class_name: "Match", optional: true

  has_many :goals, dependent: :destroy
  has_many :shootout_kicks, dependent: :destroy
  has_many :video_links, as: :linkable, dependent: :destroy
  has_many :replays, class_name: "Match", foreign_key: :replay_of_match_id, dependent: :nullify, inverse_of: :replay_of_match

  validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :date, presence: true
  validates :slug, presence: true, uniqueness: true
  validate :distinct_teams
  validate :winner_is_one_of_the_teams
  validate :teams_present_unless_placeholder

  scope :ordered_by_date, -> { order(date: :asc, id: :asc) }

  # True for a knockout slot still awaiting a team — a scheduled match in a
  # knockout round with a source label standing in for the missing team(s).
  def knockout_placeholder?
    KNOCKOUT_STAGES.include?(stage.to_s) && scheduled? &&
      (home_team.blank? || away_team.blank?) &&
      (home_source_label.present? || away_source_label.present?)
  end

  # Display label for each side: the team name, or a human reading of the
  # source label when a knockout slot is still undecided ("Winner Group E",
  # "Winner Match 74"). Lets views render placeholder matches without nil teams.
  def home_label = home_team&.name || self.class.humanize_source_label(home_source_label)
  def away_label = away_team&.name || self.class.humanize_source_label(away_source_label)

  # Humanizes a knockout placeholder source code ("1E", "2B", "3ABCDF", "W74",
  # "L101") into a readable slot label. "TBD" for anything unrecognized/blank.
  def self.humanize_source_label(code)
    case code.to_s
    when /\A1([A-L])\z/     then "Winner Group #{$1}"
    when /\A2([A-L])\z/     then "Runner-up Group #{$1}"
    when /\A3([A-L]{2,})\z/ then "3rd: #{$1.chars.join('/')}"
    when /\AW(\d+)\z/       then "Winner Match #{$1}"
    when /\AL(\d+)\z/       then "Loser Match #{$1}"
    else                         "TBD"
    end
  end

  # Compact checkmark string for the admin Matches index — Administrate
  # renders Field::Boolean as "Yes"/"No" text, so we use a String column
  # instead with an explicit ✓ glyph.
  def video
    video_links.kept.active.exists? ? "✓" : ""
  end

  # ✓ when every kept goal has at least one kept video_link whose
  # timestamp_validated_at is set. Vacuously true for goalless matches
  # (nothing to validate, so the row counts as done).
  def video_validated
    goals.kept.all? { |g| g.video_links.kept.where.not(timestamp_validated_at: nil).exists? } ? "✓" : ""
  end

  def slug_candidates
    # Teamless knockout placeholders (WC2026 bracket) have no team slugs to
    # build from, so fall back to a stable tournament+match-number slug.
    if home_team.nil? || away_team.nil?
      return ["#{tournament&.year}-match-#{match_number}", "#{tournament&.year}-#{stage}-match-#{match_number}"]
    end

    base = "#{home_team.slug}-vs-#{away_team.slug}-#{date&.year}"
    base = base.sub(/-+/, "-")
    [base, "#{base}-#{stage}"]
  end

  private

  def distinct_teams
    return if home_team_id.blank? || away_team_id.blank?
    errors.add(:away_team_id, "must differ from home team") if home_team_id == away_team_id
  end

  # Every match needs two teams — except a knockout placeholder, which may have
  # one or both sides still TBD (described by a source label instead).
  def teams_present_unless_placeholder
    return if knockout_placeholder?
    errors.add(:home_team, "can't be blank") if home_team.blank?
    errors.add(:away_team, "can't be blank") if away_team.blank?
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
#  away_source_label           :string
#  data_confidence             :integer          default("likely"), not null
#  date                        :date             not null
#  discarded_at                :datetime
#  group_letter                :string
#  home_penalties              :integer
#  home_score                  :integer          default(0), not null
#  home_score_after_extra_time :integer
#  home_source_label           :string
#  lineups_synced_at           :datetime
#  match_number                :integer
#  referee                     :string
#  result_type                 :integer          default("regulation"), not null
#  round_label                 :string
#  slug                        :string           not null
#  source_notes                :text
#  stage                       :integer          not null
#  video_scout_failed_at       :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  away_team_id                :bigint
#  home_team_id                :bigint
#  replay_of_match_id          :bigint
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
#  index_matches_on_replay_of_match_id              (replay_of_match_id)
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
#  fk_rails_...  (replay_of_match_id => matches.id)
#  fk_rails_...  (stadium_id => stadiums.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#  fk_rails_...  (winner_team_id => teams.id)
#
