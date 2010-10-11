class CustomHtml
  include MongoMapper::EmbeddedDocument

  key :_id, String
  key :top_bar, String, :default => "[[faq|FAQ]]"

  key :item_prompt, Hash, :default => {"en" => "Ask a item"}
  key :item_help, Hash, :default => {
"en" => "Please provide as much detail as possible so that it will have more
chance to be answered, you could also consider starting a <a href='/discussions/new'>discussion</a> instead of asking a item."}

  key :bookmark_prompt, Hash, :default => {"en" => "Share your bookmark"}
  key :bookmark_help, Hash, :default => {
"en" => "Please cut and paste the link of interest into this field."}

  key :discussion_prompt, Hash, :default => {"en" => "Start a discussion"}
  key :discussion_help, Hash, :default => {
"en" => "Start a discussion, if you have a specific item you may want to consider a item"}


  key :head, Hash, :default => {}
  key :footer, Hash, :default => {}
  key :head_tag, String
end
