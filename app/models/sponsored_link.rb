class SponsoredLink
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Storage

  key :_id, String
  key :_type, String
  key :name, String



  file_key :image, :max_length => 256.kilobytes
  key :image_info, Hash, :default => {"width" => 140, "height" => 40}

  key :group_id, String
  belongs_to :group


  timestamps!

end

