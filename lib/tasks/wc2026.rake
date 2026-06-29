# Rake tasks for the WC2026 live-data sync.
#
# Examples:
#   bundle exec rake wc2026:sync
#
# Requires API_FOOTBALL_KEY in env (set in .env or .kamal/secrets for prod).

namespace :wc2026 do
  desc "Sync WC2026 match scores + result_type from api-football"
  task sync: :environment do
    stats = Wc2026Sync.new.call

    puts "WC2026 sync:"
    puts "  fetched:         #{stats[:fetched]}"
    puts "  updated:         #{stats[:updated]}"
    puts "  skipped:         #{stats[:skipped]}"
    puts "  goals_synced:    #{stats[:goals_synced]}"
    puts "  players_created: #{stats[:players_created]}"
    puts "  participations:  #{stats[:participations_synced]}"
    if (b = stats[:bracket])
      puts "  bracket:         #{b[:error] ? "error: #{b[:error]}" : "changed #{b[:changed]}, filled #{b[:filled]}/#{b[:total]}"}"
    end
    if stats[:no_match].any?
      puts "  no-match fixtures (api-football side):"
      stats[:no_match].each { |line| puts "    #{line}" }
    end
  end

  desc "Fill WC2026 knockout placeholders from current standings + advance winners"
  task populate_bracket: :environment do
    stats = Wc2026BracketPopulator.call

    puts "WC2026 populate_bracket:"
    puts "  changed: #{stats[:changed]}"
    puts "  filled:  #{stats[:filled]}/#{stats[:total]}"
  end
end
