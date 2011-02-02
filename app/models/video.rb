class Video
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :_id, String
  key :_type, String
  key :video_link, String
  key :video_id, String
  key :video_provider, String
  key :video_title, String
  key :video_description, String
  key :video_keywords, String
  key :video_duration, String
  key :video_date, String
  key :video_thumbnail_small, String
  key :video_thumbnail_large, String

  timestamps!

  timestamps!

  key :item_id, String
  belongs_to :item
  validates_presence_of :item_id

end
