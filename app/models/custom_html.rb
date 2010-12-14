class CustomHtml
  include MongoMapper::EmbeddedDocument

  key :_id, String
  key :top_bar, String, :default => "[[faq|FAQ]]"

  key :item_prompt, Hash, :default => {"en" => "Publish"}
  key :item_help, Hash, :default => {
"en" => "Some helpful help text here"}


  key :head, Hash, :default => {}
  key :footer, Hash, :default => {}
  key :head_tag, String
end
