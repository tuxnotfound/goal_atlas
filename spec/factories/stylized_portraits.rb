FactoryBot.define do
  factory :stylized_portrait do
    player
    file_path    { "#{SecureRandom.hex(6)}.png" }
    generated_at { Time.current }
    is_selected  { false }
  end
end
