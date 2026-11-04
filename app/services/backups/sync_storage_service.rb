module Backups
  # Copies the files in storage/ that R2 lacks, every night. The database dump does not carry
  # them, and a stylized portrait costs an OpenAI call to make again. Only what changed goes up,
  # so a run that dies halfway resumes the next night. It never deletes from R2: a wiped volume
  # must not wipe its backup.
  class SyncStorageService < ApplicationService
    PREFIX = "goal_atlas/storage/#{Rails.env}".freeze
    ROOT = Rails.root.join("storage")

    attr_reader :uploaded

    validate :r2_configured

    private

    def execute
      remote = R2Gateway.sizes("#{PREFIX}/")
      changed = files.reject { remote[key_for(it)] == it.size }
      changed.each { upload(it) }
      @uploaded = changed.size
    end

    def r2_configured
      errors.add(:base, "R2 is not configured, so nothing would leave the box") unless R2Gateway.configured?
    end

    def files = ROOT.glob("**/*").select(&:file?)

    def key_for(path) = "#{PREFIX}/#{path.relative_path_from(ROOT)}"

    def upload(path)
      path.open("rb") { |file| R2Gateway.upload(key_for(path), file) }
    end
  end
end
