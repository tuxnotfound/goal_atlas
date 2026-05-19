# Tag iconic 2022 World Cup knockout goals.
# Tags applied are best-judgement curation, not authoritative.
#
# Depends on: goals.rb, goal_tags.rb

def goal!(slug) = Goal.friendly.find(slug)
def tag!(name)  = GoalTag.find_by!(name: name)

TAGGINGS_2022_KO = {
  # NED-ARG
  "wout-weghorst-vs-argentina-2022-83"     => ["Header from Cross"],
  "wout-weghorst-vs-argentina-2022-90"     => [], # free-kick routine; covered by goal_type

  # CRO-BRA
  "neymar-vs-croatia-2022-105"             => ["Solo Run", "Counter Attack"],
  "bruno-petkovic-vs-brazil-2022-117"      => ["Long Range"],

  # MAR-POR
  "youssef-en-nesyri-vs-portugal-2022-42"  => ["Header from Cross"],

  # ENG-FRA
  "aurelien-tchouameni-vs-england-2022-17" => ["Long Range"],
  "olivier-giroud-vs-england-2022-78"      => ["Header from Cross"],

  # ARG-CRO (SF)
  "julian-alvarez-vs-croatia-2022-39"      => ["Solo Run"],
  "julian-alvarez-vs-croatia-2022-69"      => ["One-Two", "Counter Attack"],

  # FRA-MAR (SF)
  "theo-hernandez-vs-morocco-2022-5"       => ["Volley"],
  "randal-kolo-muani-vs-morocco-2022-79"   => ["Rebound"],

  # CRO-MAR (3rd place)
  "josko-gvardiol-vs-morocco-2022-7"       => ["Header from Cross"],
  "achraf-dari-vs-croatia-2022-9"          => ["Header from Cross"],

  # Final ARG-FRA
  "angel-di-maria-vs-france-2022-36"       => ["Counter Attack"],
  "kylian-mbappe-vs-argentina-2022-81"     => ["Volley"],
  "lionel-messi-vs-france-2022-108"        => ["Rebound"]
}.freeze

count = 0
TAGGINGS_2022_KO.each do |goal_slug, tag_names|
  goal = goal!(goal_slug)
  tag_names.each do |tag_name|
    GoalTagging.find_or_create_by!(goal: goal, goal_tag: tag!(tag_name))
    count += 1
  end
end

puts "GoalTaggings: #{GoalTagging.count} (just applied: #{count})"
