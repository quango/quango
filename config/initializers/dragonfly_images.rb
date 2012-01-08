#require 'dragonfly/rails/images'
require 'rack/cache'
#require 'watermark' 
require 'image_processor'


app = Dragonfly[:images]




app.configure_with(:imagemagick)
app.configure_with(:rails)


app.configure{|c|Dragonfly::ImageMagickUtils.convert_command = '/usr/local/bin/convert'}
app.configure{|c|Dragonfly::ImageMagickUtils.identify_command = '/usr/local/bin/identify'}


#app.convert_command = "/usr/local/bin/convert"          # defaults to "convert"
#app.identify_command = "/usr/local/bin/identify"         # defaults to "convert"


app.configure{|c| c.url_host = ''} # 'http://think.it' }


app.define_macro_on_include(MongoMapper::Document, :image_accessor)
app.define_macro_on_include(MongoMapper::EmbeddedDocument, :image_accessor)

 

app.processor.register(Dragonfly::Processing::Watermark)	
app.processor.register(Dragonfly::Processing::ImageProcessor)


# Where the middleware is depends on the version of Rails
middleware = Rails.respond_to?(:application) ? Rails.application.middleware : ActionController::Dispatcher.middleware
middleware.insert_after Rack::Lock, Dragonfly::Middleware, :images, '/media'

# UNCOMMENT THIS IF YOU WANT TO CACHE REQUESTS WITH Rack::Cache

middleware.insert_before Dragonfly::Middleware, Rack::Cache, {
  :verbose     => true,
  :metastore   => "file:#{Rails.root}/tmp/dragonfly/cache/meta",
  :entitystore => "file:#{Rails.root}/tmp/dragonfly/cache/body"
}
