class VideoSection < Section
  before_validation_on_create :set_mode
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "video"
  end

end
