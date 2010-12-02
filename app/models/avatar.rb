class Avatar
  include MongoMapper::Document

  key :_id, String
  key :name, String
  key :avatar_uid, String
  key :avatar_width, Integer, :default => 48
  key :avatar_height, Integer, :default => 48
  key :avatar_cropping, String
  key :is_default, Boolean, :default => false
  
  timestamps!

  key :user_id, String, :index => true
  belongs_to :user

  #validates_presence_of :user

  THUMB_W = 256
  THUMB_H = 256
  CROP_W = 565

  validates_format_of :name, :with => /\A[a-z0-9]+\z/i

  #file_key :avatar

  image_accessor         :avatar
  validates_presence_of  :avatar
  #validates_mime_type_of :avatar, :in => %w(image/jpeg image/png image/gif)

end
