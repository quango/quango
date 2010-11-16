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
    self[:create_label] ||= "Share a link"
  end
end
