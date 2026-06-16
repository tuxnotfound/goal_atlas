require 'rails_helper'

RSpec.describe TournamentParticipation, type: :model do
  describe "validations" do
    it "is valid with minimal attributes" do
      expect(build(:tournament_participation)).to be_valid
    end

    it "rejects a duplicate participation for the same player and tournament" do
      first = create(:tournament_participation)
      duplicate = build(:tournament_participation,
                        player: first.player,
                        tournament: first.tournament)
      expect(duplicate).not_to be_valid
    end

    it "allows the same player in different tournaments" do
      first  = create(:tournament_participation)
      second = build(:tournament_participation,
                     player: first.player,
                     tournament: create(:tournament, year: first.tournament.year + 4))
      expect(second).to be_valid
    end
  end

  describe "associations" do
    it "exposes a player's participated tournaments" do
      player = create(:player)
      t2018  = create(:tournament, year: 2018)
      t2022  = create(:tournament, year: 2022)
      create(:tournament_participation, player: player, tournament: t2018)
      create(:tournament_participation, player: player, tournament: t2022)

      expect(player.participated_tournaments).to contain_exactly(t2018, t2022)
    end
  end
end

# == Schema Information
#
# Table name: tournament_participations
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  player_id     :bigint           not null
#  tournament_id :bigint           not null
#
# Indexes
#
#  index_tournament_participations_on_tournament_id  (tournament_id)
#  index_tournament_participations_uniq              (player_id,tournament_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#  fk_rails_...  (tournament_id => tournaments.id)
#
