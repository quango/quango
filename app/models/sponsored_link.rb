class SponsoredLink
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Storage

  key :_id, String
  key :_type, String
  key :name, String
  key :sponsored_link, String, :default => "Sponsored Link"
  key :sponsored_link_url, String, :default => "/"
  key :sponsored_link_text, String, :default => "Sponsored link text description"
  key :sponsored_link_image, String, :default => "/images/sponsored_link.png"

  file_key :image, :max_length => 256.kilobytes
  key :image_info, Hash, :default => {"width" => 160, "height" => 60}

  key :image_link, String
  key :group_id, String
  belongs_to :group


  timestamps!

end

