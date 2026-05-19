# Curated video links for the 2022 World Cup knockout-stage matches and goals.
#
# Sources are limited to FIFA-controlled channels (FIFA's official YouTube and
# FIFA+) plus reputable broadcaster channels (Sky Sport NZ, etc.).
#
# `confidence: :likely` is the default: URLs were located via search but not all
# were manually opened to confirm the exact content. Upgrade to `:verified` in
# admin after manual review.
#
# Depends on: matches.rb, goals.rb

def tournament_2022 = Tournament.find_by!(year: 2022)
def match!(num)     = Match.find_by!(tournament: tournament_2022, match_number: num)
def goal!(slug)     = Goal.friendly.find(slug)

# === MATCH-LEVEL ===
# FIFA YouTube highlight reel + FIFA+ full match replay.
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

# === GOAL-LEVEL ===
# FIFA+ per-goal video pages, located via search. URLs and UUIDs are stable
# across language variants (e.g. /en/ ↔ /es/ on the same UUID).
GOAL_VIDEO_LINKS = [
  # NED vs ARG
  { goal: "nahuel-molina-vs-netherlands-2022-35",
    url:  "https://www.plus.fifa.com/en/content/nahuel-molina-goal-35-netherlands-vs-argentina-fifa-world-cup-qatar-2022/e2db8793-fa50-480b-a88e-6165428867e3" },
  { goal: "lionel-messi-vs-netherlands-2022-73",
    url:  "https://www.plus.fifa.com/en/content/lionel-messi-goal-73-netherlands-vs-argentina-fifa-world-cup-qatar-2022/d91579d3-61b4-418e-a8f1-e2e86573f7ad" },
  { goal: "wout-weghorst-vs-argentina-2022-83",
    url:  "https://www.plus.fifa.com/en/content/wout-weghorst-goal-83-netherlands-vs-argentina-fifa-world-cup-qatar-2022/803bdca3-3338-44b8-9192-8c82ae9637d7" },
  { goal: "wout-weghorst-vs-argentina-2022-90",
    url:  "https://www.plus.fifa.com/en/content/wout-weghorst-goal-90-11-netherlands-vs-argentina-fifa-world-cup-qatar-2022/a040aa09-6bcc-4bbd-8d4b-b192eea1a993" },

  # CRO vs BRA
  { goal: "neymar-vs-croatia-2022-105",
    url:  "https://www.plus.fifa.com/en/content/neymar-goal-105-1-croatia-vs-brazil-fifa-world-cup-qatar-2022/94e2bc7d-7f7f-4666-89b6-2b288f269cc9" },
  { goal: "bruno-petkovic-vs-brazil-2022-117",
    url:  "https://www.plus.fifa.com/en/content/bruno-petkovic-goal-116-croatia-vs-brazil-fifa-world-cup-qatar-2022/2b4061f3-c596-4525-ad82-403d8bf59511" },

  # MAR vs POR
  { goal: "youssef-en-nesyri-vs-portugal-2022-42",
    url:  "https://www.plus.fifa.com/en/content/youssef-en-nesyri-goal-42-morocco-vs-portugal-fifa-world-cup-qatar-2022/35cd93a2-b7a4-4a2b-b971-e86c4fc83632" },

  # ENG vs FRA
  { goal: "aurelien-tchouameni-vs-england-2022-17",
    url:  "https://www.plus.fifa.com/en/content/aurelien-tchouameni-goal-17-england-vs-france-fifa-world-cup-qatar-2022/8cc42f4f-be07-437f-bc34-ec2d72499195" },
  { goal: "olivier-giroud-vs-england-2022-78",
    url:  "https://www.plus.fifa.com/en/content/olivier-giroud-goal-78-england-vs-france-fifa-world-cup-qatar-2022/ee1db323-4fe4-4b9e-96f7-3f88b1db650e" },

  # ARG vs CRO (SF)
  { goal: "lionel-messi-vs-croatia-2022-34",
    url:  "https://www.plus.fifa.com/en/content/lionel-messi-goal-34-argentina-vs-croatia-fifa-world-cup-qatar-2022/41f1a546-8031-4066-bca0-b5efe091971b" },
  { goal: "julian-alvarez-vs-croatia-2022-39",
    url:  "https://www.plus.fifa.com/en/content/julian-alvarez-goal-39-argentina-vs-croatia-fifa-world-cup-qatar-2022/21113700-c8bd-4f12-8ae8-25eff87ee79d" },
  { goal: "julian-alvarez-vs-croatia-2022-69",
    url:  "https://www.plus.fifa.com/en/content/julian-alvarez-goal-69-argentina-vs-croatia-fifa-world-cup-qatar-2022/aee96954-87af-4974-9fd9-8502d63aee5f" },

  # FRA vs MAR (SF)
  { goal: "theo-hernandez-vs-morocco-2022-5",
    url:  "https://www.plus.fifa.com/en/content/theo-hernandez-goal-5-france-vs-morocco-fifa-world-cup-qatar-2022/f16b7197-eca6-42c3-9fc0-c6463874512a" },
  { goal: "randal-kolo-muani-vs-morocco-2022-79",
    url:  "https://www.plus.fifa.com/en/content/randal-kolo-muani-goal-79-france-vs-morocco-fifa-world-cup-qatar-2022/43006d9d-cc6a-41a1-9c6c-6ed7103578c2" },

  # CRO vs MAR (3rd place)
  { goal: "josko-gvardiol-vs-morocco-2022-7",
    url:  "https://www.plus.fifa.com/en/content/josko-gvardiol-goal-7-croatia-vs-morocco-fifa-world-cup-qatar-2022/5a81b067-ff63-48c2-8e64-e1ad7500cfb1" },

  # ARG vs FRA (Final)
  { goal: "lionel-messi-vs-france-2022-23",
    url:  "https://www.plus.fifa.com/en/content/lionel-messi-goal-23-argentina-vs-france-fifa-world-cup-qatar-2022/0d0c8c59-fb72-48b8-9021-2e1737b51329" },
  { goal: "angel-di-maria-vs-france-2022-36",
    url:  "https://www.plus.fifa.com/en/content/angel-di-maria-goal-36-argentina-vs-france-fifa-world-cup-qatar-2022/06ef8ac7-e6e1-49e0-841a-c209c20b95a2" },
  { goal: "kylian-mbappe-vs-argentina-2022-81",
    url:  "https://www.plus.fifa.com/en/content/kylian-mbappe-goal-81-argentina-vs-france-fifa-world-cup-qatar-2022/9714c482-62af-4057-9299-afc6551d0a26" },
  { goal: "lionel-messi-vs-france-2022-108",
    url:  "https://www.plus.fifa.com/en/content/lionel-messi-goal-108-argentina-vs-france-fifa-world-cup-qatar-2022/5d9d78b6-b8cd-42b1-be37-4ab462b3e2aa" },
  { goal: "kylian-mbappe-vs-argentina-2022-118",
    url:  "https://www.plus.fifa.com/en/content/kylian-mbappe-goal-118-argentina-vs-france-fifa-world-cup-qatar-2022/82b12538-cd3e-4a9c-aea9-9d4323eba6c4" }
].freeze

GOAL_VIDEO_LINKS.each do |attrs|
  goal = goal!(attrs[:goal])
  goal.video_links.find_or_create_by!(url: attrs[:url]) do |link|
    link.source     = :fifa_plus
    link.confidence = :likely
    link.language   = "en"
    link.is_active  = true
  end
end

# Goals still missing per-goal FIFA+ clips (search returned no result):
#   - harry-kane-vs-france-2022-54  (penalty)
#   - achraf-dari-vs-croatia-2022-9
#   - mislav-orsic-vs-morocco-2022-42
#   - kylian-mbappe-vs-argentina-2022-80  (first final penalty)
# Use the rake task video_links:suggest to search for these later.

puts "VideoLinks: #{VideoLink.count} (target: ≥ #{MATCH_VIDEO_LINKS.size + GOAL_VIDEO_LINKS.size})"
