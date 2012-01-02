class Header
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Slugizer


  key :_id, String
  key :_type, String

  key :name, String, :default => "header"


  key :caption, String
  key :copyright, String, :default => "cc-by-3.0"
  key :copyright_url, String
  key :header_uid, String
  key :header_width, Integer, :default => 512
  key :header_height, Integer, :default => 136
  key :header_cropping, String
  key :is_default, Boolean, :default => false

  timestamps!

  key :group_id, String
  belongs_to :group
  validates_presence_of :group_id

  THUMB_W = 512
  THUMB_H = 136
  CROP_W = 512

  validates_format_of :name, :with => /\A[a-z0-9]+\z/i

  #file_key :avatar

  image_accessor         :header
  #validates_presence_of  :header
  #validates_mime_type_of :avatar, :in => %w(header/jpeg header/png header/gif)

  def up
    self.move_to("up")
  end

  def down
    self.move_to("down")
  end

  def move_to(pos)
    pos ||= "up"
    headers = item.headers
    current_pos = headers.index(self)
    if pos == "up"
      pos = current_pos-1
    elsif pos == "down"
      pos = current_pos+1
    end

    if pos >= headers.size
      pos = 0
    elsif pos < 0
      pos = headers.size-1
    end

    headers[current_pos], headers[pos] = headers[pos], headers[current_pos]
    item.headers = headers
    item.save
  end





end

