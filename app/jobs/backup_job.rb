# Nightly at 03:15, before Trained On's 03:30 copy on the shared box, so no two dumps overlap.
class BackupJob < ApplicationJob
  queue_as :default

  def perform
    Backups::RunService.new.call!
  end
end
