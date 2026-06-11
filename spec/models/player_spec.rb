require 'rails_helper'

RSpec.describe Player, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:player)).to be_valid
    end

    it "requires a name" do
      expect(build(:player, name: nil)).not_to be_valid
    end
  end

  describe "slug" do
    it "auto-generates from name" do
      messi = create(:player, :messi)
      expect(messi.slug).to eq("lionel-messi")
    end

    it "handles diacritics" do
      mbappe = create(:player, :mbappe)
      expect(mbappe.slug).to eq("kylian-mbappe")
    end
  end

  describe "position enum" do
    it "exposes the four positions" do
      expect(Player.positions.keys).to contain_exactly("goalkeeper", "defender", "midfielder", "forward")
    end

    it "allows position to be nil (unknown for historical players)" do
      expect(build(:player, position: nil)).to be_valid
    end
  end

  describe "nationality_team association" do
    it "links a player to a team" do
      argentina = create(:team, name: "Argentina")
      player = create(:player, :messi, nationality_team: argentina)
      expect(player.nationality_team).to eq(argentina)
    end

    it "allows nationality to be unset" do
      expect(build(:player, nationality_team: nil)).to be_valid
    end
  end
end

# == Schema Information
#
# Table name: players
#
#  id                     :bigint           not null, primary key
#  birth_date             :date
#  discarded_at           :datetime
#  name                   :string           not null
#  name_local             :string
#  position               :integer
#  slug                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  api_football_player_id :integer
#  nationality_team_id    :bigint
#
# Indexes
#
#  index_players_on_api_football_player_id  (api_football_player_id) UNIQUE WHERE (api_football_player_id IS NOT NULL)
#  index_players_on_discarded_at            (discarded_at)
#  index_players_on_name                    (name)
#  index_players_on_name_trgm               (name) USING gin
#  index_players_on_nationality_team_id     (nationality_team_id)
#  index_players_on_slug                    (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (nationality_team_id => teams.id)
#
