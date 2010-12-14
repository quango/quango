class Suction
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  #include MongoMapperExt::Filter

  key :_id, String
  key :_type, String
  key :name, String
  key :display_name, String
  key :doctype, String

  key :hidden, Boolean, :default => false

  key :create_label, String
  key :custom_icon, String

  timestamps!

  key :group_id, String
  belongs_to :group

  has_many :items, :dependent => :destroy

  slug_key :name, :unique => true, :min_length => 3
  key :slugs, Array, :index => true

  #validates_presence_of :group_id


  def up
    self.move_to("up")
  end

  def down
    self.move_to("down")
  end

  def move_to(pos)
    pos ||= "up"
    suctions = group.suctions
    current_pos = suctions.index(self)
    if pos == "up"
      pos = current_pos-1
    elsif pos == "down"
      pos = current_pos+1
    end

    if pos >= suctions.size
      pos = 0
    elsif pos < 0
      pos = suctions.size-1
    end

    suctions[current_pos], suctions[pos] = suctions[pos], suctions[current_pos]
    group.suctions = suctions
    group.save
  end




end

