#!/usr/bin/env ruby
# Generates a stylized portrait for a player via OpenAI gpt-image-1 and
# stores it as a StylizedPortrait row + public/stylized_portraits file.
#
# Usage:
#   bundle exec rails runner script/stylize_portrait_openai.rb "Cristiano Ronaldo"
#   bundle exec rails runner script/stylize_portrait_openai.rb cristiano-ronaldo
#
# Requires OPENAI_API_KEY in .env.

identifier = ARGV[0] || abort("Usage: rails runner script/stylize_portrait_openai.rb <player-slug-or-name>")
player = Player.friendly.find(identifier) rescue Player.find_by(name: identifier)
abort "Player not found: #{identifier}" unless player

puts "Player: #{player.name} (#{player.slug})"
puts "Source: #{player.portrait_image&.url || '(none)'}"

portrait = PortraitStylizer.new(player, logger: Rails.logger).generate!

puts "Saved:    #{portrait.file_path}"
puts "Selected: #{portrait.is_selected? ? 'yes' : 'no'} (id=#{portrait.id})"
system("open", portrait.absolute_path.to_s) if RUBY_PLATFORM =~ /darwin/
