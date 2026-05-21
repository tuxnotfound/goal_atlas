class PlayerImage < ApplicationRecord
  include Discard::Model

  belongs_to :player

  has_many :player_image_taggings, dependent: :destroy
  has_many :tournaments, through: :player_image_taggings

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :url, uniqueness: { scope: :player_id }

  scope :default, -> { where(is_default: true) }
  scope :active,  -> { where(is_active: true) }
  scope :ordered, -> { order(:position, :id) }

  def attribution_line
    parts = []
    parts << author if author.present?
    parts << license if license.present?
    parts.join(" · ").presence
  end
end

# == Schema Information
#
# Table name: player_images
#
#  id            :bigint           not null, primary key
#  author        :string
#  description   :text
#  discarded_at  :datetime
#  fetched_at    :datetime
#  is_active     :boolean          default(TRUE), not null
#  is_default    :boolean          default(FALSE), not null
#  license       :string
#  license_url   :string
#  notes         :text
#  position      :integer          default(0), not null
#  source_url    :string
#  thumbnail_url :string
#  url           :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player_id     :bigint           not null
#
# Indexes
#
#  index_player_images_on_discarded_at         (discarded_at)
#  index_player_images_on_player_id            (player_id)
#  index_player_images_on_player_id_and_url    (player_id,url) UNIQUE
#  index_player_images_one_default_per_player  (player_id,is_default) UNIQUE WHERE (is_default = true)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
