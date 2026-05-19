FactoryBot.define do
  factory :goal do
    transient do
      home_team { nil }
      away_team { nil }
    end

    match factory: :match
    player factory: :player
    scoring_team { match.home_team }
    minute { 10 }
    stoppage_time { nil }
    period { :first_half }
    goal_order { 0 }
    goal_type { :open_play }
    body_part { nil }
    assist_player { nil }
    score_after_goal_home { 1 }
    score_after_goal_away { 0 }
    description { nil }
    data_confidence { :likely }
    source_notes { nil }
    discarded_at { nil }

    trait :messi_23_vs_france do
      match { association(:match, :final_2022) }
      player { association(:player, :messi) }
      scoring_team { match.home_team }
      minute { 23 }
      period { :first_half }
      goal_type { :penalty }
      body_part { :left_foot }
      score_after_goal_home { 1 }
      score_after_goal_away { 0 }
      data_confidence { :verified }
    end

    trait :own_goal do
      goal_type { :own_goal }
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
#
# Foreign Keys
#
#  fk_rails_...  (assist_player_id => players.id)
#  fk_rails_...  (match_id => matches.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (scoring_team_id => teams.id)
#
