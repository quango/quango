class ImageSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "image"
  end
  def set_defaults
    self[:name] ||= "images"
    self[:hidden] ||= true
    self[:create_label] ||= "Upload an image"
  end
end
