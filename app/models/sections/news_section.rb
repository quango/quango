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
    self[:create_label] ||= "Share some news"
  end
end
