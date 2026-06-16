# Records that a player was part of a team's squad for a given tournament —
# i.e. they participated in that World Cup, regardless of whether they scored.
# Sourced from jfjelstul's per-player tournament list (db/seeds/import.rb).
class TournamentParticipation < ApplicationRecord
  belongs_to :player
  belongs_to :tournament

  validates :tournament_id, uniqueness: { scope: :player_id }
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
