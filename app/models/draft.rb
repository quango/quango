class Draft
  include MongoMapper::Document
  timestamps!
  key :_id, String
  key :item, Item
  key :answer, Answer
end
