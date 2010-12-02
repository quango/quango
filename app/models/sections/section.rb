class Section
  include MongoMapper::EmbeddedDocument


  key :_id, String
  key :name, String
  key :hidden, Boolean, :default => false
  key :_type, String
  key :mode, String
  key :node, String
  key :create_label, String
  key :hotness, Integer, :default => 0
  key :activity_at, Time
  key :custom_icon, String
  key :has_images, Boolean, :default => false
  key :headline_state, Boolean, :default => "closed"

  alias :group :_root_document


  has_many :items, :dependent => :destroy


  def self.types
    types = %w[NewsSection NewsfeedSection ThoughtSection VideoSection ImageSection ArticleSection DiscussionSection BookmarkSection]
    types
  end

  def self.modes
    modes = %w[Blah Bleh Bloh]
    modes
  end

  def partial_name
    "sections/#{self.name}"
  end

  def up
    self.move_to("up")
  end

  def down
    self.move_to("down")
  end

  def move_to(pos)
    pos ||= "up"
    sections = group.sections
    current_pos = sections.index(self)
    if pos == "up"
      pos = current_pos-1
    elsif pos == "down"
      pos = current_pos+1
    end

    if pos >= sections.size
      pos = 0
    elsif pos < 0
      pos = sections.size-1
    end

    sections[current_pos], sections[pos] = sections[pos], sections[current_pos]
    group.sections = sections
    group.save
  end

  def description
    @description ||= I18n.t("sections.#{self.name}.description") if self.name
  end
end

