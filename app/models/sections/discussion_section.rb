class DiscussionSection < Section
  before_validation_on_create :set_mode
  before_validation_on_create :set_defaults
  before_validation_on_update :set_mode

  protected
  def set_mode
    self[:mode] ||= "discussion"
  end
  def set_defaults
    self[:name] ||= "discussions"
    self[:create_label] ||= "Discuss something"
  end
end
