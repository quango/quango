class ProfileImage
  #include MongoMapper::EmbeddedDocument
  include MongoMapper::Document

  key :_id, String
  key :name, String, :default => "name not set"


  belongs_to :user



end

