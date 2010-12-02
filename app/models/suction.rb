class Suction
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :_id, String
  key :_type, String
  key :name, String

  timestamps!

  key :group_id, String
  belongs_to :group

  validates_presence_of :group_id

end

