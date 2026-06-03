module VideoLinksHelper
  SOURCE_LABELS = {
    "fifa_plus"        => "FIFA+",
    "youtube_official" => "YouTube",
    "archive_org"      => "Internet Archive",
    "broadcaster"      => "Broadcaster",
    "other"            => "External"
  }.freeze

  YOUTUBE_ID_REGEX = %r{
    (?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|v/|shorts/)|youtu\.be/)
    ([A-Za-z0-9_-]{11})
  }x.freeze

  def video_source_label(link)
    SOURCE_LABELS[link.source] || "Watch"
  end

  # Formats an integer second-offset as "m:ss" (under an hour) or "h:mm:ss".
  def format_seconds_as_hms(seconds)
    return nil if seconds.nil?
    s = seconds.to_i
    h, rem = s.divmod(3600)
    m, ss = rem.divmod(60)
    h.positive? ? format("%d:%02d:%02d", h, m, ss) : format("%d:%02d", m, ss)
  end

  # Accepts "443", "7:23", or "1:07:23" and returns total seconds. Returns nil
  # for blank input. Raises ArgumentError if the format is not recognized.
  # Base 10 is forced so "08" parses as 8, not as an octal error.
  def parse_hms_to_seconds(str)
    raw = str.to_s.strip
    return nil if raw.empty?
    return Integer(raw, 10) if raw.match?(/\A\d+\z/)
    parts = raw.split(":")
    raise ArgumentError, "expected m:ss or h:mm:ss, got #{raw.inspect}" unless [2, 3].include?(parts.size)
    nums = parts.map { |p| Integer(p, 10) }
    h, m, s = parts.size == 3 ? nums : [0, *nums]
    h * 3600 + m * 60 + s
  end

  # Appends ?t=<seconds> to YouTube URLs when a start timestamp is set.
  # Other sources are returned as-is (FIFA+ has no standard timestamp param).
  def video_link_url(link)
    return link.url if link.starts_at_seconds.blank?
    uri = URI.parse(link.url) rescue nil
    return link.url if uri.nil? || !uri.host.to_s.include?("youtube")
    separator = uri.query ? "&" : "?"
    "#{link.url}#{separator}t=#{link.starts_at_seconds}"
  end

  # Returns the YouTube video ID for any of the common URL shapes, or nil.
  def youtube_video_id(url)
    return nil if url.blank?
    match = url.match(YOUTUBE_ID_REGEX)
    match && match[1]
  end

  # True iff the link points at a YouTube video AND embed_allowed is set.
  def youtube_embeddable?(link)
    link.embed_allowed? && youtube_video_id(link.url).present?
  end

  # Returns the privacy-enhanced YouTube embed URL, with optional start time.
  # https://www.youtube-nocookie.com/embed/ID?start=SECONDS
  def youtube_embed_url(link)
    id = youtube_video_id(link.url)
    return nil unless id
    base = "https://www.youtube-nocookie.com/embed/#{id}"
    return base if link.starts_at_seconds.blank?
    "#{base}?start=#{link.starts_at_seconds}"
  end

  # YouTube serves thumbnails publicly without embed restrictions. Used when
  # embed_allowed is false (e.g. FIFA blocks embeds) but we still want a
  # video-shaped tile that opens YouTube on click.
  def youtube_thumbnail_url(link)
    id = youtube_video_id(link.url)
    id && "https://img.youtube.com/vi/#{id}/hqdefault.jpg"
  end

  ARCHIVE_ORG_REGEX = %r{archive\.org/(?:details|embed)/([^/?#&]+)}.freeze

  # Extracts the archive.org item identifier from either /details/ or /embed/ URLs.
  def archive_org_identifier(url)
    return nil if url.blank?
    match = url.match(ARCHIVE_ORG_REGEX)
    match && match[1]
  end

  # Archive.org content is freely embeddable by design — every public item
  # has an iframe player at /embed/IDENTIFIER. We ignore VideoLink#embed_allowed
  # for archive.org and always embed.
  def archive_org_embeddable?(link)
    archive_org_identifier(link.url).present?
  end

  def archive_org_embed_url(link)
    id = archive_org_identifier(link.url)
    id && "https://archive.org/embed/#{id}"
  end

  # Returns the best embed strategy for the section: an iframe-able link
  # (YouTube embeddable OR archive.org) with the corresponding embed URL,
  # or nil if nothing in `links` can be embedded.
  def best_embed(links)
    yt = links.find { |l| youtube_embeddable?(l) }
    return { link: yt, embed_url: youtube_embed_url(yt) } if yt
    archive = links.find { |l| archive_org_embeddable?(l) }
    return { link: archive, embed_url: archive_org_embed_url(archive) } if archive
    nil
  end
end
