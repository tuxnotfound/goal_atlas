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
    if stats[:no_match].any?
      puts "  no-match fixtures (api-football side):"
      stats[:no_match].each { |line| puts "    #{line}" }
    end
  end
end
