# Canonical goal-attribute tags.
#
# Tags describe HOW a goal was scored (technique, context) — they complement,
# rather than duplicate, the structural `goal_type` enum (open_play / penalty /
# free_kick / own_goal) and `body_part` enum.

GOAL_TAGS = [
  { name: "Header from Cross", description: "Headed goal from a cross, corner, or set-piece delivery." },
  { name: "Volley",             description: "Struck on the volley, before the ball touches the ground." },
  { name: "Bicycle Kick",       description: "Overhead/scissor kick with the body airborne." },
  { name: "Solo Run",           description: "Scorer dribbled past multiple defenders before scoring." },
  { name: "Long Range",         description: "Shot from outside the penalty area." },
  { name: "Rebound",            description: "Scored from a rebound off the keeper, post, or defender." },
  { name: "Counter Attack",     description: "Scored on a fast transition from defence to attack." },
  { name: "One-Two",            description: "Give-and-go combination played immediately before the finish." },
  { name: "Curling Shot",       description: "Notable bend or curl placed beyond the keeper's reach." },
  { name: "Chip",               description: "Lobbed or chipped over the goalkeeper." }
].freeze

GOAL_TAGS.each do |attrs|
  GoalTag.find_or_create_by!(name: attrs[:name]) do |tag|
    tag.description = attrs[:description]
  end
end

puts "GoalTags: #{GoalTag.count} (target: #{GOAL_TAGS.size})"
