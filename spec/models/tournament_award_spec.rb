require 'rails_helper'

RSpec.describe TournamentAward, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:tournament_award)).to be_valid
    end

    it "requires an award_type" do
      expect(build(:tournament_award, award_type: nil)).not_to be_valid
    end

    it "rejects two of the same award going to the same player in the same tournament" do
      first = create(:tournament_award)
      duplicate = build(:tournament_award,
                        tournament: first.tournament,
                        player: first.player,
                        award_type: first.award_type)
      expect(duplicate).not_to be_valid
    end

    it "allows the same award type to go to different players (ties)" do
      first  = create(:tournament_award, award_type: :golden_boot)
      second = build(:tournament_award,
                     tournament: first.tournament,
                     award_type: :golden_boot)
      expect(second).to be_valid
    end
  end

  describe "enum" do
    it "exposes all 8 award types" do
      expect(TournamentAward.award_types.keys).to contain_exactly(
        "golden_ball", "silver_ball", "bronze_ball",
        "golden_boot", "silver_boot", "bronze_boot",
        "golden_glove", "best_young_player"
      )
    end
  end
end

# == Schema Information
#
# Table name: tournament_awards
#
#  id            :bigint           not null, primary key
#  award_type    :integer          not null
#  notes         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player_id     :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_tournament_awards_on_award_type     (award_type)
#  index_tournament_awards_on_player_id      (player_id)
#  index_tournament_awards_on_tournament_id  (tournament_id)
#  index_tournament_awards_uniq              (tournament_id,award_type,player_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
