class RecordsController < ApplicationController
  def index
    @records = AllTimeRecords.new
  end
end
