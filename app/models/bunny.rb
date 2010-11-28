class Bunny
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :_id, String
  key :_type, String
  key :name, String

  timestamps!

  key :item_id, String
  belongs_to :item

  validates_presence_of :item_id

end

