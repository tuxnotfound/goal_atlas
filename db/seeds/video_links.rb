# Curated video links for matches and goals.
#
# This file is intentionally empty pending manual curation.
# Goal Atlas does not host footage; we link out to official sources
# (FIFA+, FIFA's YouTube channel, broadcasters) where available.
#
# To add a video link, find the goal or match record and create a VideoLink:
#
#   final = Match.find_by!(tournament: Tournament.find_by!(year: 2022), match_number: 64)
#   final.video_links.find_or_create_by!(url: "https://example.com/highlight") do |link|
#     link.source         = :youtube_official
#     link.confidence     = :verified
#     link.embed_allowed  = false
#     link.language       = "en"
#   end
#
#   messi_23 = Goal.friendly.find("lionel-messi-vs-france-2022-23")
#   messi_23.video_links.find_or_create_by!(url: "https://example.com/clip") do |link|
#     link.source            = :fifa_plus
#     link.confidence        = :verified
#     link.starts_at_seconds = 132
#   end
#
# Once curated, this file will be re-enabled in db/seeds.rb.

puts "VideoLinks: #{VideoLink.count} (no curated URLs seeded; see db/seeds/video_links.rb)"
