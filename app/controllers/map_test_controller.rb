class MapTestController < ApplicationController
  def index
  end

  def parse_query
    # Parsing code goes here
    @query = params[:query]
    redirect_to "http://maps.google.com/maps?q=#{@query.gsub(/\s+/,"+")}"
  end
end
