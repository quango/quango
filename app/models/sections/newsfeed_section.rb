class NewsfeedSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_node
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "newsfeed"
  end
  def set_node
    self[:node] ||= "Newsfeeds"
  end
end
