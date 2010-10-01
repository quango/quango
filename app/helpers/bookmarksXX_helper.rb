# Methods added to this helper will be available to all templates in the application.
module BookmarksHelper

require 'open-uri'






def showlink(link)

  return "Sausage"

end

def parsetitle(link)
  begin
    @doc = Nokogiri::HTML(open(link, "User-Agent" => "Ruby/#{RUBY_VERSION}")) 
    rescue OpenURI::HTTPError => the_error
      error_status = the_error.io.status[0]
      error_message = "Whoops got a bad status code #{error_status.message}"
  end
  title = @doc.xpath('//title')
  title_stripped = title
  #@parsetitle = scrape.to_s
  #@parsetitle = scrape.xpath("//title")
  return title_stripped
end

class URLGetCategories

 def initialize(link)
  mykey = AppConfig.alchemy_key
  endpoint = 'http://access.alchemyapi.com/calls/url/URLGetCategory?apikey='+mykey+'&url='	
  options = '' #
  @parselink = endpoint+link+options
 end

 def showlink
  #something = open(@parselink)
  #puts (something)
  return @parselink
 end 
end 


def alchemy_ranked_keywords(link)

 mykey = AppConfig.alchemy["key"]
  endpoint = 'http://access.alchemyapi.com/calls/url/URLGetRankedKeywords?apikey='+mykey+'&url='	
  options = '&keywordExtractMode=normal' # or strict &maxRetrieve=12
  @parselink = endpoint+link+options


 keywords = mykey.to_s



 return keywords

end 


class URLGetRankedEntities

 def initialize(link)
  mykey = AppConfig.alchemy["key"]
  endpoint = 'http://access.alchemyapi.com/calls/url/URLGetNamedEntities?apikey='+mykey+'&url='	
  options = '&disambiguate=1&linkedData=0&keywordExtractMode=strict' # or strict&maxRetrieve=12	
  @parselink = endpoint+link+options
 end

 def showlink
  #something = open(@parselink)
  #puts (something)
  return @parselink
 end 
end 

class URLGetRankedConcepts

 def initialize(link)
  mykey = 'bf05bde28c9947946ac1e4481c3eac4350c1a546'
  endpoint = 'http://access.alchemyapi.com/calls/url/URLGetRankedConcepts?apikey='+mykey+'&url='	

  @parselink = endpoint+link
 end

 def showlink
  #something = open(@parselink)
  #puts (something)
  return @parselink
 end 

end

end

