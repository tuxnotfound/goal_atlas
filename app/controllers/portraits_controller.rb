# Serves stylized portrait images from storage/stylized_portraits/, which
# lives on the Kamal goal_atlas_storage volume in production and is outside
# the public web root.
#
# Filenames are constrained to <slug>_<timestamp>.png by PortraitStylizer, so
# the regex below rejects path traversal and unexpected extensions.
class PortraitsController < ApplicationController
  FILENAME_RE = /\A[a-z0-9][a-z0-9\-_]*\.png\z/.freeze

  def show
    filename = params[:filename].to_s
    raise ActionController::RoutingError, "Not Found" unless filename.match?(FILENAME_RE)

    path = Rails.root.join("storage", StylizedPortrait::STORAGE_DIR, filename)
    raise ActionController::RoutingError, "Not Found" unless File.exist?(path)

    expires_in 1.year, public: true
    send_file path, type: "image/png", disposition: "inline"
  end
end
