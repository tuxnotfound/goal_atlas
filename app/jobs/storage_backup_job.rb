# Nightly at 03:20, after the database dump. Most nights nothing has changed and it only lists.
class StorageBackupJob < ApplicationJob
  queue_as :default

  def perform
    Backups::SyncStorageService.new.call!
  end
end
