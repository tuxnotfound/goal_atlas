class StylizedPortrait < ApplicationRecord
  belongs_to :player
  belongs_to :source_player_image, class_name: "PlayerImage", optional: true

  validates :file_path,    presence: true
  validates :generated_at, presence: true

  scope :selected, -> { where(is_selected: true) }
  scope :recent,   -> { order(generated_at: :desc, id: :desc) }

  # Public URL Rails serves from /public.
  def public_url
    "/#{file_path.sub(%r{\Apublic/}, "")}"
  end

  # File presence on disk — DB rows can outlive their files when devs prune
  # public/stylized_portraits/ manually.
  def file_exists?
    File.exist?(absolute_path)
  end

  def absolute_path
    Rails.root.join(file_path)
  end
end

# == Schema Information
#
# Table name: stylized_portraits
#
#  id                     :bigint           not null, primary key
#  file_path              :string           not null
#  generated_at           :datetime         not null
#  is_selected            :boolean          default(FALSE), not null
#  model                  :string
#  prompt                 :text
#  quality                :string
#  size                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  player_id              :bigint           not null
#  source_player_image_id :bigint
#
# Indexes
#
#  index_stylized_portraits_on_player_id               (player_id)
#  index_stylized_portraits_on_source_player_image_id  (source_player_image_id)
#  index_stylized_portraits_one_selected_per_player    (player_id,is_selected) UNIQUE WHERE (is_selected = true)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (source_player_image_id => player_images.id)
#
