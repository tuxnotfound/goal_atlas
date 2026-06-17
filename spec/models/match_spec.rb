require 'rails_helper'

RSpec.describe Match, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:match)).to be_valid
    end

    it "requires a date" do
      expect(build(:match, date: nil)).not_to be_valid
    end

    it "rejects identical home and away teams" do
      team = create(:team)
      match = build(:match, home_team: team, away_team: team)
      expect(match).not_to be_valid
      expect(match.errors[:away_team_id]).to include("must differ from home team")
    end

    it "rejects winner_team that is not one of the two playing teams" do
      home    = create(:team, name: "Argentina")
      away    = create(:team, name: "France")
      outside = create(:team, name: "Brazil")
      match = build(:match, home_team: home, away_team: away, winner_team: outside)
      expect(match).not_to be_valid
      expect(match.errors[:winner_team_id]).to be_present
    end

    it "rejects negative scores" do
      expect(build(:match, home_score: -1)).not_to be_valid
      expect(build(:match, away_score: -1)).not_to be_valid
    end
  end

  describe "DB constraints" do
    it "prevents identical teams at the DB level" do
      team = create(:team)
      tournament = create(:tournament)
      expect {
        Match.create!(
          tournament: tournament,
          stage: :group_stage,
          home_team_id: team.id,
          away_team_id: team.id,
          date: Date.today,
          slug: "self-vs-self"
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "2022 final scenario" do
    let(:match) { create(:match, :final_2022) }

    it "captures regulation, ET, and penalty scores" do
      expect(match.home_score).to eq(3)
      expect(match.away_score).to eq(3)
      expect(match.home_score_after_extra_time).to eq(3)
      expect(match.away_score_after_extra_time).to eq(3)
      expect(match.home_penalties).to eq(4)
      expect(match.away_penalties).to eq(2)
    end

    it "marks the correct result_type" do
      expect(match).to be_after_penalties
    end

    it "tags the winner" do
      expect(match.winner_team.name).to eq("Argentina")
    end

    it "ties to its stadium" do
      expect(match.stadium.name).to eq("Lusail Iconic Stadium")
    end
  end

  describe "slug" do
    it "builds a friendly slug from teams and year" do
      match = create(:match, :final_2022)
      expect(match.slug).to match(/argentina-vs-france-2022/)
    end
  end

  describe "stage enum" do
    it "exposes the eight stages" do
      expect(Match.stages.keys).to contain_exactly(
        "group_stage", "second_group_stage", "round_of_32", "round_of_16",
        "quarter_final", "semi_final", "third_place_playoff", "final"
      )
    end
  end

  describe "discard" do
    it "soft-deletes" do
      match = create(:match)
      match.discard
      expect(Match.kept).not_to include(match)
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
#  lineups_synced_at           :datetime
#  match_number                :integer
#  referee                     :string
#  result_type                 :integer          default("regulation"), not null
#  round_label                 :string
#  slug                        :string           not null
#  source_notes                :text
#  stage                       :integer          not null
#  video_scout_failed_at       :datetime
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
