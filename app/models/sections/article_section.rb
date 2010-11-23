class ArticleSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "article"
  end
  def set_defaults
    self[:name] ||= "articles"
    self[:has_images] ||= true
    self[:create_label] ||= "Write an article"
    self[:custom_icon] ||= "article"
  end
end
