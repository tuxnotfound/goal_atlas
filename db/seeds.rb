# Idempotent seeds for the Goal Atlas project.
#
# Run with: bin/rails db:seed
#
# Order matters: each file uses find_or_create_by! keyed on a unique attribute,
# but later seeds (e.g. matches) depend on earlier ones (teams, stadiums) existing.

require_relative "seeds/teams"
require_relative "seeds/stadiums"
require_relative "seeds/tournaments"
require_relative "seeds/import"
require_relative "seeds/goal_tags"
require_relative "seeds/goal_taggings"
require_relative "seeds/sources"
require_relative "seeds/tournament_awards"
require_relative "seeds/video_links"

puts "Seed run complete."
puts "  Tournaments:    #{Tournament.count}"
puts "  Teams:          #{Team.count}"
puts "  Stadiums:       #{Stadium.count}"
puts "  Players:        #{Player.count}"
puts "  Matches:        #{Match.count}"
puts "  Goals:          #{Goal.count}"
puts "  ShootoutKicks:  #{ShootoutKick.count}"
puts "  GoalTags:       #{GoalTag.count}"
puts "  GoalTaggings:   #{GoalTagging.count}"
puts "  Sources:        #{Source.count}"
puts "  TournamentAwards: #{TournamentAward.count}"
puts "  VideoLinks:     #{VideoLink.count}"
