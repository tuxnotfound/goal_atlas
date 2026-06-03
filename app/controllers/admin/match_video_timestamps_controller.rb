module Admin
  class MatchVideoTimestampsController < Admin::ApplicationController
    helper VideoLinksHelper

    # GET /admin/matches/:match_id/video_timestamps
    # Bulk-edit form: every goal in the match shown with its video_links and a
    # starts_at_seconds input. Lets admins watch the match highlight once and
    # set per-goal timestamps in one save.
    def edit
      @match = Match.friendly.find(params[:match_id])
      @goals = @match.goals.kept.ordered_within_match
                   .includes(:player, :scoring_team,
                             video_links: [])
      @match_video_links = @match.video_links.kept.active

      # Heuristic-based suggestions for any goal video_link missing a timestamp.
      # warm_durations! makes one cheap (1u) YouTube call to populate any
      # missing durations on first load; subsequent loads are free.
      suggester = GoalTimestampSuggester.new(@match)
      suggester.warm_durations!
      @suggestions = suggester.suggestions_by_link
    end

    # PATCH /admin/matches/:match_id/video_timestamps
    # Accepts video_links: { <video_link_id> => { starts_at: "7:23", timestamp_validated: "1" } }
    # `starts_at` is parsed from "m:ss", "h:mm:ss", or raw seconds.
    def update
      match = Match.friendly.find(params[:match_id])
      updates = params.permit(video_links: {}).to_h[:video_links] || {}

      saved = 0
      VideoLink.transaction do
        updates.each do |id, attrs|
          link = match.goals.kept.flat_map { |g| g.video_links.kept }.find { |v| v.id.to_s == id.to_s }
          link ||= match.video_links.kept.find { |v| v.id.to_s == id.to_s }
          next unless link

          changes = {}

          if attrs.key?(:starts_at)
            new_seconds = helpers.parse_hms_to_seconds(attrs[:starts_at])
            changes[:starts_at_seconds] = new_seconds if link.starts_at_seconds != new_seconds
          end

          if attrs.key?(:timestamp_validated)
            validated_now = attrs[:timestamp_validated].to_s == "1"
            if validated_now && link.timestamp_validated_at.blank?
              changes[:timestamp_validated_at] = Time.current
            elsif !validated_now && link.timestamp_validated_at.present?
              changes[:timestamp_validated_at] = nil
            end
          end

          if changes.any?
            link.update!(changes)
            saved += 1
          end
        end
      end

      redirect_to admin_match_video_timestamps_path(match),
                  notice: "Saved #{saved} change#{saved == 1 ? "" : "s"}."
    rescue ArgumentError => e
      redirect_to admin_match_video_timestamps_path(Match.friendly.find(params[:match_id])),
                  alert: "Invalid timestamp: #{e.message}"
    end
  end
end
