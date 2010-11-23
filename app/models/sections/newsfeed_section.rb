class NewsfeedSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "newsfeed"
  end
  def set_defaults
    self[:name] ||= "newsfeeds"
    self[:hidden] ||= true
    self[:create_label] ||= "Suggest a newsfeed"
    self[:custom_icon] ||= "newsfeed"
  end
end
