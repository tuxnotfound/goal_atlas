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
end
