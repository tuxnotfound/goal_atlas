# Curated video links for the 2022 World Cup knockout-stage matches and goals.
#
# Sources are limited to FIFA-controlled channels (FIFA's official YouTube and
# FIFA+) plus reputable broadcaster channels (Sky Sport NZ, etc.).
#
# `confidence: :likely` is used as a default: I verified the URLs exist via
# search but did not watch each video to confirm the exact moment shown.
# Upgrade to `:verified` after manual review.
#
# Depends on: matches.rb, goals.rb

def tournament_2022 = Tournament.find_by!(year: 2022)
def match!(num)     = Match.find_by!(tournament: tournament_2022, match_number: num)
def goal!(slug)     = Goal.friendly.find(slug)

# Match-level: FIFA's official YouTube highlight reel (1 per match) +
# FIFA+ replay where available.
MATCH_VIDEO_LINKS = [
  # NED 2-2 ARG (QF, Argentina win 4-3 on pens)
  { match: 57, source: :youtube_official, url: "https://www.youtube.com/watch?v=0i-gsQJg7jc",
    notes: "FIFA YouTube — Late Weghorst goal & PENALTIES | Netherlands v Argentina | Quarter-Final" },
  { match: 57, source: :fifa_plus, url: "https://www.plus.fifa.com/en/content/netherlands-v-argentina-quarter-finals-fifa-world-cup-qatar-2022-full-match-replay/5f24e303-ff42-499f-9d7a-b4f8e0eff2ce",
    notes: "FIFA+ — full match replay" },

  # CRO 1-1 BRA (QF, Croatia win 4-2 on pens)
  { match: 58, source: :youtube_official, url: "https://www.youtube.com/watch?v=wnfiXhNVudk",
    notes: "FIFA YouTube — Penalty DRAMA! | Croatia v Brazil | Quarter-Final" },

  # MAR 1-0 POR (QF)
  { match: 59, source: :youtube_official, url: "https://www.youtube.com/watch?v=5GVitElttLY",
    notes: "FIFA YouTube — En-Nesyri Leaps Into History! | Morocco vs Portugal" },
  { match: 59, source: :fifa_plus, url: "https://www.plus.fifa.com/en/content/morocco-v-portugal-quarter-finals-fifa-world-cup-qatar-2022-full-match-replay/5f1b5797-25d0-4e10-b723-5072b470bae8",
    notes: "FIFA+ — full match replay" },

  # ENG 1-2 FRA (QF)
  { match: 60, source: :broadcaster, url: "https://www.youtube.com/watch?v=v4Mp6e4AkIk",
    notes: "Sky Sport NZ — HIGHLIGHTS: England v France (Quarter-Final)" },

  # ARG 3-0 CRO (SF)
  { match: 61, source: :youtube_official, url: "https://www.youtube.com/watch?v=gbkgbbKZ1CA",
    notes: "FIFA YouTube — MESSI MAGIC & ALVAREZ SOLO GOAL! | Argentina v Croatia | Semi-Final" },

  # FRA 2-0 MAR (SF)
  { match: 62, source: :youtube_official, url: "https://www.youtube.com/watch?v=PHjukOhzFLE",
    notes: "FIFA YouTube — Allez Les Bleus | France v Morocco | Semi-Final" },
  { match: 62, source: :fifa_plus, url: "https://www.plus.fifa.com/en/content/france-v-morocco-semi-finals-fifa-world-cup-qatar-2022-full-match-replay/6992ab23-d7a7-4ea3-85be-23772013be63",
    notes: "FIFA+ — full match replay" },

  # CRO 2-1 MAR (3rd place)
  { match: 63, source: :youtube_official, url: "https://www.youtube.com/watch?v=hg8pcLDn-pI",
    notes: "FIFA YouTube — MODRIC'S BOYS TAKE BRONZE | Croatia v Morocco" },
  { match: 63, source: :fifa_plus, url: "https://www.plus.fifa.com/en/content/croatia-v-morocco-play-off-for-third-place-fifa-world-cup-qatar-2022/09e75c23-ec7d-4a6c-8b67-786e8c8c2627",
    notes: "FIFA+ — full match" },

  # ARG 3-3 FRA (Final, Argentina win 4-2 on pens)
  { match: 64, source: :youtube_official, url: "https://www.youtube.com/watch?v=zhEWqfP6V_w",
    notes: "FIFA YouTube — THE GREATEST FINAL EVER?! | Argentina v France" },
  { match: 64, source: :youtube_official, url: "https://www.youtube.com/watch?v=IipmpVcISXE",
    notes: "FIFA YouTube — Argentina v France: 2022 #FIFAWorldCup Final Highlights" },
  { match: 64, source: :youtube_official, url: "https://www.youtube.com/watch?v=MCWJNOfJoSM",
    notes: "FIFA YouTube — Full Penalty Shoot-out" }
].freeze

MATCH_VIDEO_LINKS.each do |attrs|
  match = match!(attrs[:match])
  match.video_links.find_or_create_by!(url: attrs[:url]) do |link|
    link.source     = attrs[:source]
    link.confidence = :likely
    link.language   = "en"
    link.is_active  = true
  end
end

# Goal-level: dedicated FIFA+ "wonder goal" clips where I found them.
GOAL_VIDEO_LINKS = [
  { goal: "neymar-vs-croatia-2022-105", source: :fifa_plus,
    url: "https://www.plus.fifa.com/en/content/neymar-goal-105-1-croatia-vs-brazil-fifa-world-cup-qatar-2022/94e2bc7d-7f7f-4666-89b6-2b288f269cc9",
    notes: "FIFA+ — Neymar goal 105+1' | Croatia vs Brazil" }
].freeze

GOAL_VIDEO_LINKS.each do |attrs|
  goal = goal!(attrs[:goal])
  goal.video_links.find_or_create_by!(url: attrs[:url]) do |link|
    link.source     = attrs[:source]
    link.confidence = :likely
    link.language   = "en"
    link.is_active  = true
  end
end

puts "VideoLinks: #{VideoLink.count} (target: #{MATCH_VIDEO_LINKS.size + GOAL_VIDEO_LINKS.size})"
