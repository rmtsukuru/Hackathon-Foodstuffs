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
    categories = []
    params[:query].gsub! /(#{yelp_categories.keys.join('|')})/i do |match|
      categories.push yelp_categories[match.downcase]
      ''
    end
    distance_units = {meters: 1, kilometers: 1000, miles: 1609.34}
    params[:query].gsub!(/((\d*\.)?\d+)\s+(#{distance_units.keys.join('|')})/, '')
    if $1
      radius = $1.to_f
      if distance_units.has_key? $3.to_sym
        radius *= distance_units[$3.to_sym]
      end
    end
    params[:query].strip!
    params[:query].gsub!(/\s+/, ' ')
    limit = 10
    puts "Query: #{params[:query]}  Radius: #{radius}"
    access_token = OAuthAccessor.access_token
    
    path = "/v2/search?term=#{URI::encode(params[:query])}&ll=#{params[:latitude]},#{params[:longitude]}&radius_filter=#{radius.to_i}&limit=#{limit}&category_filter=#{categories.join(',')}"

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

  def list_categories
    @categories = yelp_categories.keys
  end

  private

  def yelp_categories
    {"bagels"=>"bagels", "bakeries"=>"bakeries", "beer, wine & spirits"=>"beer_and_wine", "breweries"=>"breweries", "bubble tea"=>"bubbletea", "butcher"=>"butcher", "csa"=>"csa", "coffee & tea"=>"coffee", "convenience stores"=>"convenience", "desserts"=>"desserts", "do-it-yourself food"=>"diyfood", "donuts"=>"donuts", "farmers market"=>"farmersmarket", "food delivery services"=>"fooddeliveryservices", "food trucks"=>"foodtrucks", "gelato"=>"gelato", "grocery"=>"grocery", "ice cream & frozen yogurt"=>"icecream", "internet cafes"=>"internetcafe", "juice bars & smoothies"=>"juicebars", "pretzels"=>"pretzels", "shaved ice"=>"shavedice", "specialty food"=>"gourmet", "candy stores"=>"candy", "cheese shops"=>"cheese", "chocolatiers & shops"=>"chocolate", "ethnic food"=>"ethnicmarkets", "fruits & veggies"=>"markets", "health markets"=>"healthmarkets", "herbs & spices"=>"herbsandspices", "meat shops"=>"meats", "seafood markets"=>"seafoodmarkets", "street vendors"=>"streetvendors", "tea rooms"=>"tea", "wineries"=>"wineries", "afghan"=>"afghani", "african"=>"african", "senegalese"=>"senegalese", "south african"=>"southafrican", "american (new)"=>"newamerican", "american (traditional)"=>"tradamerican", "arabian"=>"arabian", "argentine"=>"argentine", "armenian"=>"armenian", "asian fusion"=>"asianfusion", "australian"=>"australian", "austrian"=>"austrian", "bangladeshi"=>"bangladeshi", "barbeque"=>"bbq", "basque"=>"basque", "belgian"=>"belgian", "brasseries"=>"brasseries", "brazilian"=>"brazilian", "breakfast & brunch"=>"breakfast_brunch", "british"=>"british", "buffets"=>"buffets", "burgers"=>"burgers", "burmese"=>"burmese", "cafes"=>"cafes", "cafeteria"=>"cafeteria", "cajun/creole"=>"cajun", "cambodian"=>"cambodian", "caribbean"=>"caribbean", "dominican"=>"dominican", "haitian"=>"haitian", "puerto rican"=>"puertorican", "trinidadian"=>"trinidadian", "catalan"=>"catalan", "cheesesteaks"=>"cheesesteaks", "chicken wings"=>"chicken_wings", "chinese"=>"chinese", "cantonese"=>"cantonese", "dim sum"=>"dimsum", "shanghainese"=>"shanghainese", "szechuan"=>"szechuan", "comfort food"=>"comfortfood", "creperies"=>"creperies", "cuban"=>"cuban", "czech"=>"czech", "delis"=>"delis", "diners"=>"diners", "ethiopian"=>"ethiopian", "fast food"=>"hotdogs", "filipino"=>"filipino", "fish & chips"=>"fishnchips", "fondue"=>"fondue", "food court"=>"food_court", "food stands"=>"foodstands", "french"=>"french", "gastropubs"=>"gastropubs", "german"=>"german", "gluten-free"=>"gluten_free", "greek"=>"greek", "halal"=>"halal", "hawaiian"=>"hawaiian", "himalayan/nepalese"=>"himalayan", "hot dogs"=>"hotdog", "hot pot"=>"hotpot", "hungarian"=>"hungarian", "iberian"=>"iberian", "indian"=>"indpak", "indonesian"=>"indonesian", "irish"=>"irish", "italian"=>"italian", "japanese"=>"japanese", "korean"=>"korean", "kosher"=>"kosher", "laotian"=>"laotian", "latin american"=>"latin", "colombian"=>"colombian", "salvadoran"=>"salvadoran", "venezuelan"=>"venezuelan", "live/raw food"=>"raw_food", "malaysian"=>"malaysian", "mediterranean"=>"mediterranean", "mexican"=>"mexican", "middle eastern"=>"mideastern", "egyptian"=>"egyptian", "lebanese"=>"lebanese", "modern european"=>"modern_european", "mongolian"=>"mongolian", "moroccan"=>"moroccan", "pakistani"=>"pakistani", "persian/iranian"=>"persian", "peruvian"=>"peruvian", "pizza"=>"pizza", "polish"=>"polish", "portuguese"=>"portuguese", "russian"=>"russian", "salad"=>"salad", "sandwiches"=>"sandwiches", "scandinavian"=>"scandinavian", "scottish"=>"scottish", "seafood"=>"seafood", "singaporean"=>"singaporean", "slovakian"=>"slovakian", "soul food"=>"soulfood", "soup"=>"soup", "southern"=>"southern", "spanish"=>"spanish", "steakhouses"=>"steak", "sushi bars"=>"sushi", "taiwanese"=>"taiwanese", "tapas bars"=>"tapas", "tapas/small plates"=>"tapasmallplates", "tex-mex"=>"tex-mex", "thai"=>"thai", "turkish"=>"turkish", "ukrainian"=>"ukrainian", "vegan"=>"vegan", "vegetarian"=>"vegetarian", "vietnamese"=>"vietnamese"}
  end
end
