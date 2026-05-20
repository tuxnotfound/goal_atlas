FactoryBot.define do
  factory :match do
    tournament
    stage { :group_stage }
    round_label { nil }
    group_letter { "A" }
    match_number { 1 }
    home_team factory: :team
    association :away_team, factory: :team
    home_score { 0 }
    away_score { 0 }
    home_score_after_extra_time { nil }
    away_score_after_extra_time { nil }
    home_penalties { nil }
    away_penalties { nil }
    date { Date.new(2022, 11, 20) }
    stadium { nil }
    attendance { nil }
    referee { nil }
    result_type { :regulation }
    winner_team { nil }
    data_confidence { :likely }
    source_notes { nil }
    slug { nil }
    discarded_at { nil }

    trait :final_2022 do
      tournament { association(:tournament, :wc_2022) }
      stage { :final }
      home_team { association(:team, name: "Argentina") }
      away_team { association(:team, name: "France") }
      home_score { 3 }
      away_score { 3 }
      home_score_after_extra_time { 3 }
      away_score_after_extra_time { 3 }
      home_penalties { 4 }
      away_penalties { 2 }
      date { Date.new(2022, 12, 18) }
      stadium { association(:stadium, :lusail) }
      attendance { 88_966 }
      result_type { :after_penalties }
      data_confidence { :verified }
      winner_team { home_team }
    end
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
