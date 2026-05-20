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
