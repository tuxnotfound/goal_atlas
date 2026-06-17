# Aggregates a player's contributions across one tournament — goals, assists,
# shootout kicks, awards. The set of tournaments is driven by the player's
# recorded squad participations (TournamentParticipation), so a tournament the
# player took part in but didn't score/assist/kick in still gets a record (with
# zero counts). Evidence tournaments are unioned in as a safety net in case a
# participation row is missing.
#
# Use PlayerTournamentRecord.for_player(player) to get the full set in one shot;
# it issues a constant number of queries regardless of tournament count.
class PlayerTournamentRecord
  attr_reader :player, :tournament

  def initialize(player, tournament, goals:, assists:, shootout_kicks:, awards:)
    @player        = player
    @tournament    = tournament
    @goals_list    = goals
    @assists_list  = assists
    @kicks_list    = shootout_kicks
    @awards_list   = awards
  end

  def self.for_player(player)
    # Own goals credit the opposing team, so they never count toward this
    # player's goals_count (nor appear in their per-tournament goal list).
    goals   = player.goals.kept.excluding_own_goals.includes(match: :tournament).to_a
    assists = Goal.kept.where(assist_player_id: player.id).includes(match: :tournament).to_a
    kicks   = ShootoutKick.kept.where(player_id: player.id).includes(match: :tournament).to_a
    awards  = TournamentAward.where(player_id: player.id).includes(:tournament).to_a

    tournament_ids = (
      player.tournament_participations.pluck(:tournament_id) +
      goals.map   { |g| g.match.tournament_id } +
      assists.map { |a| a.match.tournament_id } +
      kicks.map   { |k| k.match.tournament_id } +
      awards.map(&:tournament_id)
    ).uniq

    Tournament.kept.where(id: tournament_ids).ordered_by_year.map do |t|
      new(
        player,
        t,
        goals:          goals.select   { |g| g.match.tournament_id == t.id },
        assists:        assists.select { |a| a.match.tournament_id == t.id },
        shootout_kicks: kicks.select   { |k| k.match.tournament_id == t.id },
        awards:         awards.select  { |a| a.tournament_id == t.id }
      )
    end
  end

  def goals_count   = @goals_list.size
  def assists_count = @assists_list.size

  def shootout_kicks_count  = @kicks_list.size
  def shootout_kicks_scored = @kicks_list.count(&:was_scored)
  def shootout_kicks_missed = shootout_kicks_count - shootout_kicks_scored

  def goals         = @goals_list
  def awards        = @awards_list
  def shootout_kicks = @kicks_list
  def has_award?    = @awards_list.any?

  def empty?
    goals_count.zero? && assists_count.zero? && shootout_kicks_count.zero? && !has_award?
  end
end
