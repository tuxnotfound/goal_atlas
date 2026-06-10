#!/usr/bin/env ruby
# Generates hero assets (trophy + world map) via OpenAI gpt-image-1's
# text-to-image generation endpoint, in the painterly style that
# matches the player portraits. Output PNGs land in /public/ where the
# hero dispatcher picks them up automatically.
#
# Usage:
#   bundle exec rails runner script/generate_hero_assets.rb trophy
#   bundle exec rails runner script/generate_hero_assets.rb map
#   bundle exec rails runner script/generate_hero_assets.rb all
#
# Requires OPENAI_API_KEY in .env.

require "net/http"
require "json"
require "base64"
require "fileutils"

OPENAI_GEN = "https://api.openai.com/v1/images/generations".freeze
MODEL      = "gpt-image-1".freeze
QUALITY    = "high".freeze
PUBLIC_DIR = "public".freeze

ASSETS = {
  "trophy" => {
    filename: "hero_trophy.png",
    size:     "1024x1536", # portrait
    prompt:   <<~PROMPT.strip
      The FIFA World Cup trophy, painterly digital illustration in the
      style of high-end sports-magazine illustrations or FIFA Ultimate
      Team card art. Solid gold trophy with two stylized human figures
      curving upward to support a globe at the top, two malachite green
      bands stacked into the base. Centered, isolated. Soft directional
      lighting from the upper left, warm gold tones with subtle metallic
      reflections, smooth vector-style shading — NOT flat colors, NOT
      posterized, NOT cartoon. Painterly brush strokes visible on the
      metal surfaces.

      CRITICAL FRAMING RULES:
      - The output canvas is portrait (taller than wide).
      - The full trophy from base to globe must be visible and centered.
      - At least 10% empty space above the globe and below the base.
      - Fully transparent background — no fill, no scenery, no shadow plate.
      - No border, no frame around the image.
      - No text, no words, no logos, no FIFA branding.
    PROMPT
  },
  "map" => {
    filename: "hero_world_map.png",
    size:     "1536x1024", # landscape
    prompt:   <<~PROMPT.strip
      A vintage-style painterly illustration of the world map seen as
      simplified continent silhouettes. Same illustrative treatment as
      a high-end sports-magazine illustration or vintage tournament
      programme art. Continents filled with soft sepia and warm forest-
      green tones, subtle gold highlights, painterly brush strokes
      visible on the surface. NOT flat colors, NOT posterized, NOT
      cartoon.

      CRITICAL FRAMING RULES:
      - The output canvas is landscape (wider than tall).
      - All major continents visible: North America, South America,
        Europe, Africa, Asia, Australia, and a hint of Antarctica.
      - Fully transparent background — oceans are transparent, only the
        continent silhouettes carry colour.
      - No border, no frame around the image.
      - No country borders, no political boundaries.
      - No labels, no text, no city markers, no compass rose.
      - No latitude/longitude lines, no equator.
    PROMPT
  }
}.freeze

def generate(asset_key, asset, api_key)
  puts ""
  puts "=== Generating #{asset_key} (#{asset[:size]}) → #{asset[:filename]} ==="
  puts "Prompt: #{asset[:prompt].lines.first.strip}..."

  uri  = URI(OPENAI_GEN)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl      = true
  http.read_timeout = 240

  req = Net::HTTP::Post.new(uri.request_uri)
  req["Authorization"] = "Bearer #{api_key}"
  req["Content-Type"]  = "application/json"
  req.body = {
    model:      MODEL,
    prompt:     asset[:prompt],
    size:       asset[:size],
    quality:    QUALITY,
    background: "transparent",
    n:          1
  }.to_json

  res = http.request(req)
  unless res.is_a?(Net::HTTPSuccess)
    abort "OpenAI HTTP #{res.code}: #{res.body[0, 400]}"
  end

  data = JSON.parse(res.body)
  b64  = data.dig("data", 0, "b64_json")
  abort "OpenAI returned no image: #{data.inspect[0, 400]}" if b64.nil?

  FileUtils.mkdir_p(PUBLIC_DIR)
  out_path = File.join(PUBLIC_DIR, asset[:filename])
  File.binwrite(out_path, Base64.decode64(b64))

  puts "Saved: #{out_path} (#{(File.size(out_path) / 1024.0).round(1)} KB)"
  system("open", out_path) if RUBY_PLATFORM =~ /darwin/
end

api_key = ENV["OPENAI_API_KEY"] || abort("OPENAI_API_KEY not set in environment")

target = ARGV[0] || abort(<<~USAGE)
  Usage:
    bundle exec rails runner script/generate_hero_assets.rb <trophy|map|all>
USAGE

case target
when "trophy", "map"
  generate(target, ASSETS[target], api_key)
when "all"
  ASSETS.each { |key, asset| generate(key, asset, api_key) }
else
  abort "Unknown target: #{target}. Expected 'trophy', 'map', or 'all'."
end

puts ""
puts "Done. Refresh /world-cups/2022 — the dispatcher will pick up the new asset(s)."
