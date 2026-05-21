FactoryBot.define do
  factory :player_image do
    player
    sequence(:url) { |n| "https://commons.wikimedia.org/file_#{n}.jpg" }
    source_url    { "https://commons.wikimedia.org/wiki/File:Example.jpg" }
    thumbnail_url { url }
    license       { "CC BY-SA 4.0" }
    license_url   { "https://creativecommons.org/licenses/by-sa/4.0/" }
    author        { "Example Author" }
    description   { "Example portrait" }
    is_default    { false }
    is_active     { true }
    position      { 0 }
    fetched_at    { Time.current }

    trait :default do
      is_default { true }
    end

    trait :inactive do
      is_active { false }
    end
  end
end

# == Schema Information
#
# Table name: player_images
#
#  id                 :bigint           not null, primary key
#  author             :string
#  commons_categories :string           default([]), is an Array
#  description        :text
#  discarded_at       :datetime
#  fetched_at         :datetime
#  image_height       :integer
#  image_width        :integer
#  is_active          :boolean          default(TRUE), not null
#  is_default         :boolean          default(FALSE), not null
#  license            :string
#  license_url        :string
#  notes              :text
#  position           :integer          default(0), not null
#  source_url         :string
#  thumbnail_url      :string
#  url                :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  player_id          :bigint           not null
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
