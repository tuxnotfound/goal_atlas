require "net/http"
require "json"
require "base64"
require "fileutils"
require "securerandom"

# Generates a stylized portrait of a player by sending their current
# portrait_image to OpenAI gpt-image-1's /v1/images/edits endpoint with a
# vector-illustration prompt, post-processing the result through
# ImageMagick (crop + flood-fill background), and creating a
# StylizedPortrait DB row.
#
# Reusable from the admin "Regenerate" button and the CLI script.
class PortraitStylizer
  USER_AGENT  = "GoalAtlas/0.1 (https://goalatlas.local; pcioga@gmail.com)".freeze
  OPENAI_EDIT = "https://api.openai.com/v1/images/edits".freeze
  MAGICK_BIN  = "/opt/homebrew/bin/magick".freeze

  PROMPT = <<~PROMPT.strip
    Restyle this photo as a high-end vector portrait illustration, in the
    style of professional sports-magazine illustrations or FIFA Ultimate
    Team card art. Smooth vector-style shading with realistic skin tones
    and soft color gradients — NOT flat colors, NOT posterized, NOT
    cartoon. Detailed face: preserve the specific facial features,
    jawline, eyes, eyebrows, hair texture and individual hair strands.
    No harsh black outlines around the face or body — use soft tonal
    transitions and clean vector edges instead.

    CRITICAL FRAMING RULES:
    - The output canvas is portrait (taller than wide).
    - The TOP of the head (including the entire hair, not just the
      hairline) MUST sit in the upper third of the image with at least
      15% empty white space above the highest point of the hair.
    - The head, hair, ears, and full neckline must all be fully visible.
    - DO NOT crop, cut, or push any part of the head against the top
      edge of the canvas.
    - It is acceptable to show the upper shoulders and the collar of the
      shirt at the bottom of the frame, but stop there — no chest, no
      full jersey, no team badge.

    Background: solid pure white (#FFFFFF), no cream, no off-white, no
    texture, no scenery.

    Add a thin dark border around the entire image.

    No text, no words, no logos, no jersey numbers, no team badges.
  PROMPT

  PUBLIC_DIR = "public/stylized_portraits".freeze

  # If true the freshly-generated portrait is automatically marked
  # is_selected when no other selection exists for the player.
  AUTO_SELECT_FIRST = true

  def initialize(player, api_key: ENV["OPENAI_API_KEY"], model: "gpt-image-1",
                 quality: "high", size: "1024x1536", logger: nil)
    @player  = player
    @api_key = api_key
    @model   = model
    @quality = quality
    @size    = size
    @logger  = logger
  end

  # Returns the persisted StylizedPortrait or raises.
  def generate!
    raise ArgumentError, "OPENAI_API_KEY not configured" if @api_key.blank?
    src = @player.portrait_image
    raise "Player #{@player.name} has no portrait_image to stylize" if src.nil?

    src_bytes, src_url, mime = download_source(src)
    raw_b64 = call_openai(src_bytes, mime)
    file_path = post_process_and_save(raw_b64)

    portrait = StylizedPortrait.create!(
      player: @player,
      source_player_image: src,
      file_path: file_path,
      model: @model,
      quality: @quality,
      size: @size,
      prompt: PROMPT,
      generated_at: Time.current
    )

    if AUTO_SELECT_FIRST && @player.stylized_portraits.selected.empty?
      portrait.update!(is_selected: true)
    end

    portrait
  end

  private

  def download_source(image)
    candidates = [image.thumbnail(width: 1024).presence, image.url].compact.uniq
    candidates.each do |url|
      res = http_get(url)
      if res.is_a?(Net::HTTPSuccess)
        mime = url.match?(/\.png/i) ? "image/png" : "image/jpeg"
        return [res.body, url, mime]
      else
        @logger&.warn("Download #{url} failed (HTTP #{res.code}); trying next candidate")
      end
    end
    raise "Source download failed for #{image.url}"
  end

  def http_get(url)
    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.read_timeout = 180
    req  = Net::HTTP::Get.new(uri.request_uri)
    req["User-Agent"] = USER_AGENT
    http.request(req)
  end

  def call_openai(src_bytes, mime)
    boundary = "----GoalAtlas#{SecureRandom.hex(12)}"
    ext      = mime == "image/png" ? "png" : "jpg"

    body = String.new(encoding: Encoding::ASCII_8BIT)
    body << form_part(boundary, "model",   @model)
    body << form_part(boundary, "prompt",  PROMPT)
    body << form_part(boundary, "size",    @size)
    body << form_part(boundary, "quality", @quality)
    body << form_part(boundary, "n",       "1")
    body << "--#{boundary}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"src.#{ext}\"\r\nContent-Type: #{mime}\r\n\r\n".b
    body << src_bytes.b
    body << "\r\n--#{boundary}--\r\n".b

    uri  = URI(OPENAI_EDIT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 240
    req = Net::HTTP::Post.new(uri.request_uri)
    req["Authorization"] = "Bearer #{@api_key}"
    req["Content-Type"]  = "multipart/form-data; boundary=#{boundary}"
    req.body = body

    res = http.request(req)
    unless res.is_a?(Net::HTTPSuccess)
      raise "OpenAI HTTP #{res.code}: #{res.body[0, 400]}"
    end

    data = JSON.parse(res.body)
    b64  = data.dig("data", 0, "b64_json")
    raise "OpenAI returned no image: #{data.inspect[0, 400]}" if b64.nil?
    b64
  end

  def form_part(boundary, name, value)
    "--#{boundary}\r\nContent-Disposition: form-data; name=\"#{name}\"\r\n\r\n#{value}\r\n".b
  end

  # Saves the raw output, then crops + flood-fills to produce the final image
  # at public/stylized_portraits/<slug>_<timestamp>.png. Returns the path
  # relative to the repo root for storage in DB.
  def post_process_and_save(b64)
    unless File.executable?(MAGICK_BIN)
      raise "ImageMagick not found at #{MAGICK_BIN}"
    end

    FileUtils.mkdir_p(PUBLIC_DIR)
    ts        = Time.current.to_i
    raw_path  = File.join(PUBLIC_DIR, "#{@player.slug}_#{ts}_raw.png")
    out_path  = File.join(PUBLIC_DIR, "#{@player.slug}_#{ts}.png")
    File.binwrite(raw_path, Base64.decode64(b64))

    crop_path = "#{raw_path}.crop.png"
    unless system(MAGICK_BIN, raw_path, "-gravity", "north", "-crop", "100%x70%+0+0", "+repage", crop_path)
      raise "ImageMagick crop failed"
    end

    dims = `#{MAGICK_BIN} identify -format "%w %h" #{crop_path}`.split.map(&:to_i)
    w, h = dims
    unless system(MAGICK_BIN, crop_path,
                  "-fuzz", "15%",
                  "-fill", "white",
                  "-draw", "color 0,0 floodfill",
                  "-draw", "color #{w - 1},0 floodfill",
                  "-draw", "color 0,#{h - 1} floodfill",
                  "-draw", "color #{w - 1},#{h - 1} floodfill",
                  out_path)
      raise "ImageMagick floodfill failed"
    end
    File.delete(crop_path)

    out_path
  end
end
