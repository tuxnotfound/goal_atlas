FactoryBot.define do
  factory :tournament_award do
    tournament
    player
    award_type { :golden_ball }
    notes { nil }
  end
end
