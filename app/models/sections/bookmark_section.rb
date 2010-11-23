class BookmarkSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "bookmark"
  end
  def set_defaults
    self[:name] ||= "bookmarks"
    self[:create_label] ||= "Share a bookmark"
    self[:custom_icon] ||= "bookmark"
  end
end
