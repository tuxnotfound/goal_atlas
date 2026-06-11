FactoryBot.define do
  factory :stylized_portrait do
    player
    file_path    { "#{SecureRandom.hex(6)}.png" }
    generated_at { Time.current }
    is_selected  { false }
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
