class SponsoredLink
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :_id, String
  key :_type, String
  key :name, String

  key :group_id, String
  belongs_to :group


  timestamps!

end

