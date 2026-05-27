# Trusted video sources used across all tournaments.
#
# Each Source records WHERE we curate video links from. These are the
# rights-holding or licensed channels we trust to link out to. The
# `notes` field documents specifics (YouTube channel ID, scope of
# coverage, geo-restrictions) so VideoLinkScout and future tools can
# resolve them.
#
# When adding a new tournament, prefer linking to one of these sources
# rather than ad-hoc YouTube uploads.

SOURCES = [
  {
    name: "FIFA YouTube",
    url: "https://www.youtube.com/@FIFA",
    reliability: :official,
    notes: <<~NOTES.strip
      Official YouTube channel of FIFA. Posts match highlights, per-goal clips,
      and short-form recap content for major tournaments.
      YouTube channel ID: UCpcTrCXblq78GZrTUTLWeBw
      Used by VideoLinkScout as the default channel for video_links:suggest_*.
    NOTES
  },
  {
    name: "FIFA+",
    url: "https://www.plus.fifa.com",
    reliability: :official,
    notes: <<~NOTES.strip
      FIFA's official streaming platform. Hosts full match replays, extended
      highlights, and per-goal clip pages for World Cups since 2022.
      Per-goal URL pattern:
        /en/content/<player-name>-goal-<minute>-<home>-vs-<away>-fifa-world-cup-qatar-2022/<uuid>
      Some content is geo-restricted.
    NOTES
  },
  {
    name: "Sky Sport NZ",
    url: "https://www.youtube.com/@SkySportNZ",
    reliability: :high,
    notes: <<~NOTES.strip
      New Zealand broadcaster's official YouTube. Posts FIFA World Cup match
      highlights under license. Useful when FIFA's own channel hasn't uploaded
      a particular match.
      YouTube channel ID: UC8f1U3h2TAcKOktgonnL0Yw
    NOTES
  },
  {
    name: "TyC Sports",
    url: "https://www.youtube.com/@TycSports",
    reliability: :high,
    notes: <<~NOTES.strip
      Argentine sports broadcaster. Strong coverage of Argentine national team
      matches — useful fallback for 2022 Argentina goals when FIFA's channel
      lacks a specific clip.
      YouTube channel ID: UC72ZaBKI-Bo5fjmWEYonhJw
    NOTES
  },
  {
    name: "TF1",
    url: "https://www.youtube.com/@TF1",
    reliability: :high,
    notes: <<~NOTES.strip
      French national broadcaster. Holds rights to the French national team
      and posts highlights on YouTube. Useful fallback for 2022 France goals.
      YouTube channel ID: UC26vXhYofHiZDM2ar1zUuwQ
    NOTES
  },
  {
    name: "BBC Sport",
    url: "https://www.youtube.com/@bbcsport",
    reliability: :high,
    notes: <<~NOTES.strip
      UK broadcaster. Posts post-match analysis and selected highlights;
      sometimes uploads goal-only clips that FIFA's channel doesn't have.
      YouTube channel ID: UCW6-BQWFA70Dyyc7ZpZ9Xlg
    NOTES
  },
  {
    name: "RTP Notícias",
    url: "https://www.youtube.com/@RTPNoticias",
    reliability: :high,
    notes: <<~NOTES.strip
      Portuguese public broadcaster news channel. Posts Portugal national
      team coverage — fallback for 2022 Portugal goals.
      YouTube channel ID: UCIM-wfyv9hg2oEiA81mQc2A
    NOTES
  }
].freeze

SOURCES.each do |attrs|
  Source.find_or_create_by!(name: attrs[:name]) do |source|
    source.url = attrs[:url]
    source.reliability = attrs[:reliability]
    source.notes = attrs[:notes]
  end
end

puts "Sources: #{Source.count} (target: #{SOURCES.size})"
