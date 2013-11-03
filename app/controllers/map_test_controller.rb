class MapTestController < ApplicationController


  def index
  end

  def query_google
    @query = params[:query]
    redirect_to "http://maps.google.com/maps?q=#{@query.gsub(/\s+/,"+")}"
  end

  def parse_query
    # Parsing code goes here
	@message = "Some restaurants that you may like are shown on the map.<br />"
	getAmbDis = false
	ambRadiusDef = 5

    price_words = { cheap: 1..1, inexpensive: 2..2, expensive: 3..3, exorbitant: 4..4, ludicrous: 4..4 }
    price_range = nil
    params[:query].gsub! /(#{price_words.keys.join('|')})/i do |match|
      price_range = price_words[match.to_sym]
      ''
    end

    params[:radius] = (5 * 1609.34).to_i
    categories = []
    params[:query].gsub! /(#{yelp_categories.keys.join('|')})/i do |match|
      categories.push yelp_categories[match.downcase]
      ''
    end
	
	params[:query].gsub! /(#{ambiguous_distance_keyword.join('|')})/i do |match|
	  ambRadius (ambRadiusDef)
	  getAmbDis = true
	  ambRadiusDef += 1
	end
	
    distance_units = {meter: 1, meters: 1, kilometer: 1000, kilometers: 1000, mile: 1609.34, miles: 1609.34}
    params[:query].gsub!(/((\d*\.)?\d+)\s+(#{distance_units.keys.join('|')})/, '')
    if $1
      params[:radius] = $1.to_f
      if distance_units.has_key? $3.to_sym
        params[:radius] *= distance_units[$3.to_sym]
      end
	  getAmbDis = false
    end
    params[:query].strip!
    params[:query].gsub!(/\s+/, ' ')

    terms = []
    params[:query].gsub! /(#{term_list.join('|')})/i do |match|
      terms.push match.downcase
      ''
    end
	
    if categories.empty?
      categories << 'food' << 'restaurants'
      if (params[:radius].class == Fixnum) and terms.empty?
        @message = "Please provide more details about what you want to eat ╮(╯_╰)╭"
        params[:query] = "asdfasdf"
      end
    end
    limit = 10

    puts "Query: #{params[:query]}  Radius: #{params[:radius]}"
    access_token = OAuthAccessor.access_token
    
    path = "/v2/search?term=#{URI::encode terms.join(' ')}&ll=#{params[:latitude]},#{params[:longitude]}&radius_filter=#{params[:radius].to_i}&limit=#{limit}&category_filter=#{categories.join(',')}"

    @results = JSON.parse(access_token.get(path).body)
	
	if getAmbDis
	  while @results['total'].to_i < 10 && ambRadiusDef <= 8
	    puts @results['total']
		puts ambRadiusDef
	    ambRadius (ambRadiusDef)
	    path = "/v2/search?term=#{URI::encode terms.join(' ')}&ll=#{params[:latitude]},#{params[:longitude]}&radius_filter=#{params[:radius].to_i}&limit=#{limit}&category_filter=#{categories.join(',')}"
		@results = JSON.parse(access_token.get(path).body)
		ambRadiusDef += 1
      end
	end

    require 'open-uri'
    require 'nokogiri'
    if price_range
      @results['businesses'].select! do |business|
        doc = Nokogiri::HTML(open(business['url'], 'User-Agent' => 'ruby'))
	price = doc.search('#price_tip').text.count '$'
        price_range.include? price
      end
    end

    if @results['businesses'].empty?
      @message = "No establishments in that price range available."
    end
	
    @results['businesses'].each do |business|
      address = URI::encode("#{business['location']['address'].join(', ')}, #{business['location']['city']}, #{business['location']['state_code']}")
      geocode = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address}&sensor=true").read)
      business['location']['latitude'] = geocode['results'].first['geometry']['location']['lat']
      business['location']['longitude'] = geocode['results'].first['geometry']['location']['lng']
    end

    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def ambRadius (dist)
      params[:radius] = (dist * 1609.34)
	  @message = "We find some restaurant within #{dist} miles. <br />"
  end

  def list_categories
    @categories = yelp_categories.keys
  end

  private

  def term_list
    ['a la carte','accessible','accompaniment','acerbic','acidulated','acrid','addictive','additives','adjustment','aficionado','alcoholic','aliment','all natural','allergy','alternative','ambiance','ample','anchovies','appeal','appetite','appliance','aroma','arrangement','artisan','artistic','arugula','assortment','atmosphere','attractive','availability','balance','balsamic','barbecue','basics','baste','batter','beans','beets','beverage','bitterness','blend','bonbon','bountiful','bouquet','braise','brazier','brew','buffet','cabbage','calorie','carbohydrate','carcinogen','carnivore','casserole','cast iron','caterer','celery','chef','chewy','chicken','chicory','chipotle','chips','chocolate','chocolatier','choice','cholesterol','chop','chow','churn','chutney','classic','clean','cleaver','cocoa','coffee','color','combination','comestible','comfort food','complementary','complimentary','compote','compromise','condiment','confection','confection','confectionary','connoisseur','consistency','consume','consumer','content','convenience','cooked','cooking','crackers','creative','cress','crop','crop failure','croutons','crunchy','cucumbers','cuisine','culinary','cultural','curd','curdle','curiosity','customs','cutlery','cutting board','dairy','de-vein','decanter','degrees','delectable','delicious','desiccate','dessert','devour','diary','diet','dietary','digestible','discoloration','distillery','dominate','douse','drizzle','eatery','economical','edible','effervescent','eggs','elasticity','elixir','endive','energy','enjoyment','enthusiast','entree','environment-friendly','enzyme','exceptional','expand','expensive','experiment','expresso','famine','fare','farm-fresh','farmer','fast food','feast','filtered','fish','fizz','flagon','flake','flapjack','flavorful','flavoring','fluffy','focus','fodder','fortifying','fowl','fragrant','fresh','frozen','fruit','fusion','gadget','garden fresh','garnish','gastric','gastro-tourism','gastronomy','gelato','gizmo','gluten','goblet','gorge','gourmet','grains','granulate','grate','greens','grill','guest','guide','habits','haggis','ham','harvest','haute cuisine','healthy','hearty','heat','high-quality','home economics','homemade','hors- d\'oeuvres','hunger','identification','imbibe','impact','importance','imported','improvement','incorporate','indigestion','industry','inexpensive','influenced','ingredient','innovative','insatiable','interchangeable','irresistible','jigger','juicy','julienne','junk food','keen','kitchen','kosher','ladle','larder','lavish','leavening','leftover','legendary','legume','lettuce','life style','liquor','local','low fat','mandolin','marinade','marinate','market','meal','meat','medicinal','memorable','menu','meringue','microwave','milk','mince','mincemeat','mixture','mouthwatering','munch','mustard','natural','needs','neutralize','nibble','nonstick','nourish','nourishment','nutriment','nutrition','nuts','odor','odoriferous','onions','option','organic','overcook','overshadow','packaging','palate','panache','pantry','parfait','pasta','pasteurize','pastry','pectin','peeler','pepper','peppery','percolate','pilsner','placebo','platter','pop','popularity','portion','potable','potion','preference','premium','preparation','presentation','preservative','prime','process','processed','produce','production','provision','purveyor','putrid','quality','quantity','quart','quiche','quick','quinoa','radish','ramekin','rating','ravenous','raw','reaction','recipe','recommendation','refined','refreshing','regimen','regulatory','reheat','reliability','religion','relish','research','reservation','restaurant','restaurateur','rich','ripe','roasted','salivate','salsa','salty','salver','sample','satiated','satisfied','saturate','sauce','saute','savory','scour','scrumptious','seafood','seasonal','seasoning','selection','senses','serrated','service','shortage','shortening','sieve','silicone spatula','simmer','skewer','skillet','slice','slow-roast','slurp','smoky','snacks','soft drink','sommelier','sophistication','soul satisfying','sour','sous-chef','spatula','special','specialty','spice','spinach','sprinkle','stale','starvation','statin','steam','sticky','storage','store-bought','strong','substitute','succulent','supermarket','supplements','supplies','supply','sustenance','sweet','tangy','tapas','tart','taste','taste buds','tasteless','tasty','tea','temperature','texture','thermometer','thermos','thickener','timer','tomato','tongs','toppings','toss','tour de force','toxic','traditional','trend','trifle','trivet','truffle','truss','undercook','ungreased','uniformity','unique','unmold','upgrade','upscale','utensil','value','variation','variety','vascular','vegetable','venue','viand','victuals','vinegar','vintner','vitamin','wafer','wassail','wedge','weight','whisk','wine','yogurt','yummy','zanthrophylls','zest','zester','zip','zucchini']
  end

  def yelp_categories
    {"bagels"=>"bagels", "bakeries"=>"bakeries", "beer, wine & spirits"=>"beer_and_wine", "breweries"=>"breweries", "bubble tea"=>"bubbletea", "butcher"=>"butcher", "csa"=>"csa", "coffee & tea"=>"coffee", "convenience stores"=>"convenience", "desserts"=>"desserts", "do-it-yourself food"=>"diyfood", "donuts"=>"donuts", "farmers market"=>"farmersmarket", "food delivery services"=>"fooddeliveryservices", "food trucks"=>"foodtrucks", "gelato"=>"gelato", "grocery"=>"grocery", "ice cream & frozen yogurt"=>"icecream", "internet cafes"=>"internetcafe", "juice bars & smoothies"=>"juicebars", "pretzels"=>"pretzels", "shaved ice"=>"shavedice", "specialty food"=>"gourmet", "candy stores"=>"candy", "cheese shops"=>"cheese", "chocolatiers & shops"=>"chocolate", "ethnic food"=>"ethnicmarkets", "fruits & veggies"=>"markets", "health markets"=>"healthmarkets", "herbs & spices"=>"herbsandspices", "meat shops"=>"meats", "seafood markets"=>"seafoodmarkets", "street vendors"=>"streetvendors", "tea rooms"=>"tea", "wineries"=>"wineries", "afghan"=>"afghani", "african"=>"african", "senegalese"=>"senegalese", "south african"=>"southafrican", "american (new)"=>"newamerican", "american (traditional)"=>"tradamerican", "arabian"=>"arabian", "argentine"=>"argentine", "armenian"=>"armenian", "asian fusion"=>"asianfusion", "australian"=>"australian", "austrian"=>"austrian", "bangladeshi"=>"bangladeshi", "barbeque"=>"bbq", "basque"=>"basque", "belgian"=>"belgian", "brasseries"=>"brasseries", "brazilian"=>"brazilian", "breakfast & brunch"=>"breakfast_brunch", "british"=>"british", "buffets"=>"buffets", "burgers"=>"burgers", "burmese"=>"burmese", "cafes"=>"cafes", "cafeteria"=>"cafeteria", "cajun/creole"=>"cajun", "cambodian"=>"cambodian", "caribbean"=>"caribbean", "dominican"=>"dominican", "haitian"=>"haitian", "puerto rican"=>"puertorican", "trinidadian"=>"trinidadian", "catalan"=>"catalan", "cheesesteaks"=>"cheesesteaks", "chicken wings"=>"chicken_wings", "chinese"=>"chinese", "cantonese"=>"cantonese", "dim sum"=>"dimsum", "shanghainese"=>"shanghainese", "szechuan"=>"szechuan", "comfort food"=>"comfortfood", "creperies"=>"creperies", "cuban"=>"cuban", "czech"=>"czech", "delis"=>"delis", "diners"=>"diners", "ethiopian"=>"ethiopian", "fast food"=>"hotdogs", "filipino"=>"filipino", "fish & chips"=>"fishnchips", "fondue"=>"fondue", "food court"=>"food_court", "food stands"=>"foodstands", "french"=>"french", "gastropubs"=>"gastropubs", "german"=>"german", "gluten-free"=>"gluten_free", "greek"=>"greek", "halal"=>"halal", "hawaiian"=>"hawaiian", "himalayan/nepalese"=>"himalayan", "hot dogs"=>"hotdog", "hot pot"=>"hotpot", "hungarian"=>"hungarian", "iberian"=>"iberian", "indian"=>"indpak", "indonesian"=>"indonesian", "irish"=>"irish", "italian"=>"italian", "japanese"=>"japanese", "korean"=>"korean", "kosher"=>"kosher", "laotian"=>"laotian", "latin american"=>"latin", "colombian"=>"colombian", "salvadoran"=>"salvadoran", "venezuelan"=>"venezuelan", "live/raw food"=>"raw_food", "malaysian"=>"malaysian", "mediterranean"=>"mediterranean", "mexican"=>"mexican", "middle eastern"=>"mideastern", "egyptian"=>"egyptian", "lebanese"=>"lebanese", "modern european"=>"modern_european", "mongolian"=>"mongolian", "moroccan"=>"moroccan", "pakistani"=>"pakistani", "persian/iranian"=>"persian", "peruvian"=>"peruvian", "pizza"=>"pizza", "polish"=>"polish", "portuguese"=>"portuguese", "russian"=>"russian", "salad"=>"salad", "sandwiches"=>"sandwiches", "scandinavian"=>"scandinavian", "scottish"=>"scottish", "seafood"=>"seafood", "singaporean"=>"singaporean", "slovakian"=>"slovakian", "soul food"=>"soulfood", "soup"=>"soup", "southern"=>"southern", "spanish"=>"spanish", "steakhouses"=>"steak", "sushi bars"=>"sushi", "taiwanese"=>"taiwanese", "tapas bars"=>"tapas", "tapas/small plates"=>"tapasmallplates", "tex-mex"=>"tex-mex", "thai"=>"thai", "turkish"=>"turkish", "ukrainian"=>"ukrainian", "vegan"=>"vegan", "vegetarian"=>"vegetarian", "vietnamese"=>"vietnamese"}
  end
  
  def ambiguous_distance_keyword
    ["far", "close", "around", "away", "block", "long", "short"]
  end
end
