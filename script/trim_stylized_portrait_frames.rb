#!/usr/bin/env ruby
# Trims the rounded-rectangle frame the AI image generator baked into the
# stylized portraits. Each frame shows up as a thin dark border around the
# subject; `object-fit: cover` then exposes its top edge as a horizontal bar
# at the top of the rendered avatar.
#
# Strategy: ImageMagick's -trim removes the white margin outside the frame,
# then -shave crops a few pixels off each side to slice past the frame stroke
# itself. The result is the portrait alone, no frame, no margin.
#
# We process the "served" copies (the ones avatar.html.erb actually points to,
# e.g. abdelhamid-sabiri_1779885111.png) and leave their _raw siblings alone
# so we can re-trim if the shave needs tuning.
#
# Usage:
#   ruby script/trim_stylized_portrait_frames.rb            # process all
#   ruby script/trim_stylized_portrait_frames.rb --dry-run  # report only

require "open3"
require "shellwords"
require "fileutils"

DIR        = File.expand_path("../public/stylized_portraits", __dir__)
MAGICK     = ENV["MAGICK_BIN"] || "/opt/homebrew/bin/magick"
SHAVE_PX   = 18  # frame stroke is ~7-8px + a couple of pixels of safety
DRY_RUN    = ARGV.include?("--dry-run")

abort "magick not found at #{MAGICK}" unless File.executable?(MAGICK)
abort "portraits directory missing: #{DIR}" unless Dir.exist?(DIR)

served_pngs = Dir.glob(File.join(DIR, "*.png")).reject { |f| f.end_with?("_raw.png") }

puts "processing #{served_pngs.size} stylized portraits (shave=#{SHAVE_PX}px, dry_run=#{DRY_RUN})"

processed = 0
skipped   = 0
failed    = []

served_pngs.each_with_index do |path, i|
  basename = File.basename(path)

  # Sanity guard: skip files already small enough that another trim would
  # likely shave into the face (idempotent reruns are fine, but log them).
  width, height = `#{MAGICK} identify -format "%w %h" #{path.shellescape}`.split.map(&:to_i)
  if width < 200 || height < 200
    skipped += 1
    puts "  [skip] #{basename} (too small: #{width}x#{height})"
    next
  end

  if DRY_RUN
    processed += 1
    puts "  [dry] would trim #{basename} (#{width}x#{height})"
    next
  end

  tmp = "#{path}.tmp.png"
  cmd = [MAGICK, path, "-trim", "+repage", "-shave", "#{SHAVE_PX}x#{SHAVE_PX}", tmp]
  _, stderr, status = Open3.capture3(*cmd)

  if status.success? && File.exist?(tmp) && File.size(tmp) > 0
    FileUtils.mv(tmp, path)
    processed += 1
    print "." if (processed % 25).zero?
  else
    failed << basename
    File.delete(tmp) if File.exist?(tmp)
    puts "\n  [fail] #{basename}: #{stderr.strip}"
  end
end

puts ""
puts "done — processed=#{processed} skipped=#{skipped} failed=#{failed.size}"
puts "failed files: #{failed.inspect}" if failed.any?
