class Image

  include MongoMapper::Document

  key :_id, String
  key :_type, String
  key :name, String

end

