class Image
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :_id, String
  key :_type, String
  key :name, String
  key :image_uid, String
  key :image_width, Integer, :default => 256
  key :image_height, Integer, :default => 144
  key :image_cropping, String

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



end

