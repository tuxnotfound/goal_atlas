module SeoHelper
  SITE_NAME = "The Goal Atlas".freeze
  DEFAULT_DESCRIPTION =
    "An interactive archive of every FIFA World Cup match, goal, and player. " \
    "Highlights linked from official sources, with timelines, awards, and search.".freeze
  DEFAULT_OG_IMAGE = "/icon.png".freeze

  def seo_for(title:, description:, og_image: nil, noindex: false)
    content_for :title, "#{title} — #{SITE_NAME}"
    content_for :meta_description, description
    content_for(:og_image, og_image) if og_image
    content_for(:noindex, "true") if noindex
  end

  def page_title
    content_for?(:title) ? content_for(:title) : SITE_NAME
  end

  def page_description
    content_for?(:meta_description) ? content_for(:meta_description) : DEFAULT_DESCRIPTION
  end

  def page_og_image_url
    path = content_for?(:og_image) ? content_for(:og_image) : DEFAULT_OG_IMAGE
    return path if path.start_with?("http://", "https://")
    "#{request.base_url}#{path}"
  end

  def page_noindex?
    content_for?(:noindex)
  end

  def canonical_url
    request.original_url.split("?").first
  end
end
