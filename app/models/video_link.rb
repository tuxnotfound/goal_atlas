class VideoLink < ApplicationRecord
  include Discard::Model

  SOURCES = {
    fifa_plus: 0,
    youtube_official: 1,
    archive_org: 2,
    broadcaster: 3,
    other: 4
  }.freeze

  CONFIDENCES = {
    verified: 0,
    likely: 1,
    unverified: 2
  }.freeze

  ALLOWED_LINKABLE_TYPES = %w[Match Goal].freeze

  enum :source, SOURCES
  enum :confidence, CONFIDENCES, prefix: :confidence

  belongs_to :linkable, polymorphic: true

  validates :url, presence: true,
                  format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :linkable_type, inclusion: { in: ALLOWED_LINKABLE_TYPES }
  validates :starts_at_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ends_at_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :end_after_start

  scope :active, -> { where(is_active: true) }
  scope :embeddable, -> { where(embed_allowed: true) }

  private

  def end_after_start
    return if starts_at_seconds.blank? || ends_at_seconds.blank?
    errors.add(:ends_at_seconds, "must be greater than starts_at_seconds") if ends_at_seconds <= starts_at_seconds
  end
end

# == Schema Information
#
# Table name: video_links
#
#  id                :bigint           not null, primary key
#  confidence        :integer          default("likely"), not null
#  discarded_at      :datetime
#  embed_allowed     :boolean          default(FALSE), not null
#  ends_at_seconds   :integer
#  is_active         :boolean          default(TRUE), not null
#  language          :string
#  last_checked_at   :datetime
#  linkable_type     :string           not null
#  source            :integer          not null
#  starts_at_seconds :integer
#  url               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  linkable_id       :bigint           not null
#
# Indexes
#
#  index_video_links_on_discarded_at  (discarded_at)
#  index_video_links_on_is_active     (is_active)
#  index_video_links_on_linkable      (linkable_type,linkable_id)
#  index_video_links_on_source        (source)
#
