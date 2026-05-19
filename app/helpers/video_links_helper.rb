module VideoLinksHelper
  SOURCE_LABELS = {
    "fifa_plus"        => "FIFA+",
    "youtube_official" => "YouTube",
    "archive_org"      => "Internet Archive",
    "broadcaster"      => "Broadcaster",
    "other"            => "External"
  }.freeze

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
end
