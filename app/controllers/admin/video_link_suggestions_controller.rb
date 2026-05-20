module Admin
  class VideoLinkSuggestionsController < Admin::ApplicationController
    layout "application"

    # GET /admin/video_link_suggestions
    # GET /admin/video_link_suggestions?linkable_type=Goal&linkable_id=42
    def index
      @matches = Match.kept.includes(:home_team, :away_team).ordered_by_date
      @goals   = Goal.kept.includes(:player, :scoring_team, match: :tournament)
                          .joins(:match).order("matches.date ASC, goals.minute ASC").references(:match)

      return unless params[:linkable_type].in?(%w[Match Goal]) && params[:linkable_id].present?

      klass = params[:linkable_type].constantize
      @linkable = klass.find(params[:linkable_id])

      @results = case @linkable
                 when Match then ::VideoLinkScout.new.suggest_for_match(@linkable)
                 when Goal  then ::VideoLinkScout.new.suggest_for_goal(@linkable)
                 end
    rescue ::VideoLinkScout::ApiKeyMissing => e
      @error = "Set the YOUTUBE_API_KEY env var in .env to enable search. (#{e.message})"
    rescue ::VideoLinkScout::ApiError => e
      @error = "YouTube API error: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      @error = "That #{params[:linkable_type]} doesn't exist."
    end

    # POST /admin/video_link_suggestions
    # Creates a VideoLink from a selected search result.
    def create
      klass = params[:linkable_type].constantize
      raise ActionController::BadRequest unless klass.in?([Match, Goal])

      linkable = klass.find(params[:linkable_id])
      link = linkable.video_links.find_or_create_by!(url: params[:url]) do |l|
        l.source     = params[:source].presence || :youtube_official
        l.confidence = :likely
        l.language   = "en"
        l.is_active  = true
      end

      flash[:notice] = "Linked #{linkable.class.model_name.human} → #{link.url}"
      redirect_to admin_video_link_suggestions_path(
        linkable_type: params[:linkable_type],
        linkable_id:   params[:linkable_id]
      )
    end
  end
end
