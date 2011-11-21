module MetaHelper

  def get_terms

    terms = "Hello world"
    terms

  end



  protected
  def escape_url(url)
    URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end
