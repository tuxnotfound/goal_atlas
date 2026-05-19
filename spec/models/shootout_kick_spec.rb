require 'rails_helper'

RSpec.describe ShootoutKick, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:shootout_kick)).to be_valid
    end

    it "requires kick_order > 0" do
      expect(build(:shootout_kick, kick_order: 0)).not_to be_valid
      expect(build(:shootout_kick, kick_order: nil)).not_to be_valid
    end

    it "requires explicit was_scored (no nil)" do
      expect(build(:shootout_kick, was_scored: nil)).not_to be_valid
    end

    it "rejects team that is not in the match" do
      match    = create(:match, :final_2022)
      outside  = create(:team, name: "Brazil")
      kick = build(:shootout_kick, match: match, team: outside)
      expect(kick).not_to be_valid
      expect(kick.errors[:team_id]).to be_present
    end
  end

  describe "uniqueness of kick_order per match" do
    it "rejects duplicate kick_order within a single match at DB level" do
      match = create(:match, :final_2022)
      create(:shootout_kick, match: match, kick_order: 1)
      expect {
        ShootoutKick.create!(
          match: match,
          team: match.home_team,
          player: create(:player),
          kick_order: 1,
          was_scored: true
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "tracks misses (not just goals)" do
    it "stores was_scored=false" do
      kick = create(:shootout_kick, was_scored: false, notes: "saved by Lloris")
      expect(kick.was_scored).to be false
      expect(kick.notes).to eq("saved by Lloris")
    end
  end
end

# == Schema Information
#
# Table name: shootout_kicks
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  kick_order   :integer          not null
#  notes        :string
#  was_scored   :boolean          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  match_id     :bigint           not null
#  player_id    :bigint           not null
#  team_id      :bigint           not null
#
# Indexes
#
#  index_shootout_kicks_on_discarded_at         (discarded_at)
#  index_shootout_kicks_on_match_id             (match_id)
#  index_shootout_kicks_on_player_id            (player_id)
#  index_shootout_kicks_on_team_id              (team_id)
#  index_shootout_kicks_unique_order_per_match  (match_id,kick_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (match_id => matches.id)
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (team_id => teams.id)
#
