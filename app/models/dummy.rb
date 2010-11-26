class Dummy

  include MongoMapper::Document

  key :_id, String
  key :_type, String
  key :name, String

end

