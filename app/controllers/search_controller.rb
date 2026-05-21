class SearchController < ApplicationController
  def index
    @query   = params[:q].to_s.strip
    @results = Search.new(@query)
  end
end
