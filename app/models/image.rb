class Image
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Slugizer


  key :_id, String
  key :_type, String

  key :name, String, :default => "image"


  key :caption, String
  key :copyright, String
  key :copyright_url, String
  key :image_uid, String
  key :image_width, Integer, :default => 256
  key :image_height, Integer, :default => 144
  key :image_cropping, String
  key :is_default, Boolean, :default => false

  timestamps!

  key :item_id, String
  belongs_to :item
  validates_presence_of :item_id

  THUMB_W = 256
  THUMB_H = 144
  CROP_W = 565

  validates_format_of :name, :with => /\A[a-z0-9]+\z/i

  #file_key :avatar

  image_accessor         :image
  #validates_presence_of  :image
  #validates_mime_type_of :avatar, :in => %w(image/jpeg image/png image/gif)

  def up
    self.move_to("up")
  end

  def down
    self.move_to("down")
  end

  def move_to(pos)
    pos ||= "up"
    images = item.images
    current_pos = images.index(self)
    if pos == "up"
      pos = current_pos-1
    elsif pos == "down"
      pos = current_pos+1
    end

    if pos >= images.size
      pos = 0
    elsif pos < 0
      pos = images.size-1
    end

    images[current_pos], images[pos] = images[pos], images[current_pos]
    item.images = images
    item.save
  end





end

