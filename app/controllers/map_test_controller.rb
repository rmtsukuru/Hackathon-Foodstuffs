class MapTestController < ApplicationController


  def index
  end

  def query_google
    @query = params[:query]
    redirect_to "http://maps.google.com/maps?q=#{@query.gsub(/\s+/,"+")}"
  end

  def parse_query
    # Parsing code goes here
    radius = 5000
    params[:query].gsub!(/(\d+)\s+meters/, '')
    if $1
      radius = $1
    end
    params[:query].strip!
    params[:query].gsub!(/\s+/, ' ')
    puts "Query: #{params[:query]}"
    access_token = OAuthAccessor.access_token
    
    path = "/v2/search?term=#{URI::encode(params[:query])}&ll=#{params[:latitude]},#{params[:longitude]}&radius_filter=#{radius}"

    @results = JSON.parse(access_token.get(path).body)
    @results['businesses'].each do |business|
      address = URI::encode("#{business['location']['address'].join(', ')}, #{business['location']['city']}, #{business['location']['state_code']}")
      require 'open-uri'
      geocode = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address}&sensor=true").read)
      business['location']['latitude'] = geocode['results'].first['geometry']['location']['lat']
      business['location']['longitude'] = geocode['results'].first['geometry']['location']['lng']
    end

    respond_to do |format|
      format.html
      format.js
    end
  end
end
