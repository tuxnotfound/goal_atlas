require 'rails_helper'

RSpec.describe Goal, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:goal)).to be_valid
    end

    it "requires minute, score_after_goal_*" do
      expect(build(:goal, minute: nil)).not_to be_valid
      expect(build(:goal, score_after_goal_home: nil)).not_to be_valid
      expect(build(:goal, score_after_goal_away: nil)).not_to be_valid
    end

    it "rejects negative minute" do
      expect(build(:goal, minute: -1)).not_to be_valid
    end

    it "rejects assist_player being the same as the scorer" do
      messi = create(:player, :messi)
      match = create(:match, :final_2022)
      goal = build(:goal, match: match, player: messi, scoring_team: match.home_team, assist_player: messi)
      expect(goal).not_to be_valid
      expect(goal.errors[:assist_player_id]).to be_present
    end

    it "rejects scoring_team not in the match" do
      match    = create(:match, :final_2022)
      outside  = create(:team, name: "Brazil")
      goal = build(:goal, match: match, scoring_team: outside)
      expect(goal).not_to be_valid
      expect(goal.errors[:scoring_team_id]).to be_present
    end
  end

  describe "own goal semantics" do
    it "credits the opposing team, not the scorer's team" do
      match = create(:match, :final_2022)
      argentina_player = create(:player, name: "Some Argentine", nationality_team: match.home_team)

      # Own goal: argentine player scores into own net, France gets credit
      good = build(:goal, :own_goal,
                   match: match,
                   player: argentina_player,
                   scoring_team: match.away_team)
      expect(good).to be_valid

      # Bug case: own goal credited to scorer's own team
      bad = build(:goal, :own_goal,
                  match: match,
                  player: argentina_player,
                  scoring_team: match.home_team)
      expect(bad).not_to be_valid
      expect(bad.errors[:goal_type]).to be_present
    end
  end

  describe "ordered_within_match scope" do
    it "orders by (period, minute, stoppage_time, goal_order)" do
      match = create(:match, :final_2022)
      g_5 = create(:goal, match: match, scoring_team: match.home_team,
                          minute: 5,  period: :first_half,
                          score_after_goal_home: 1, score_after_goal_away: 0)
      g_45_2 = create(:goal, match: match, scoring_team: match.home_team,
                             minute: 45, stoppage_time: 2, period: :first_half,
                             score_after_goal_home: 2, score_after_goal_away: 0)
      g_60 = create(:goal, match: match, scoring_team: match.away_team,
                           minute: 60, period: :second_half,
                           score_after_goal_home: 2, score_after_goal_away: 1)
      g_108 = create(:goal, match: match, scoring_team: match.home_team,
                            minute: 108, period: :extra_time_first,
                            score_after_goal_home: 3, score_after_goal_away: 1)

      expect(match.goals.ordered_within_match).to eq([g_5, g_45_2, g_60, g_108])
    end
  end

  describe "enums" do
    it "exposes period values" do
      expect(Goal.periods.keys).to contain_exactly(
        "first_half", "second_half", "extra_time_first", "extra_time_second"
      )
    end

    it "exposes goal_type values" do
      expect(Goal.goal_types.keys).to contain_exactly(
        "open_play", "penalty", "free_kick", "own_goal"
      )
    end

    it "exposes body_part values" do
      expect(Goal.body_parts.keys).to contain_exactly(
        "right_foot", "left_foot", "head", "other"
      )
    end
  end

  describe "discard" do
    it "soft-deletes" do
      goal = create(:goal)
      goal.discard
      expect(Goal.kept).not_to include(goal)
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
#  slug                  :string           not null
#  source_notes          :text
#  stoppage_time         :integer
#  video_scout_failed_at :datetime
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
#  index_goals_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (assist_player_id => players.id)
#  fk_rails_...  (match_id => matches.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (scoring_team_id => teams.id)
#
