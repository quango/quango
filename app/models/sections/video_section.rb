class VideoSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "video"
  end
  def set_defaults
    self[:name] ||= "video"
    self[:create_label] ||= "Suggest a video"
  end
end
