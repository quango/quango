class NewsSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "news"
  end
  def set_defaults
    self[:name] ||= "news"
    self[:has_images] ||= true
    self[:create_label] ||= "Tell us your news"
    self[:custom_icon] ||= "news"
  end
end
