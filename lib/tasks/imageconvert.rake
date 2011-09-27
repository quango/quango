desc "Fix images"
task :fiximages => [:environment, "imageconvert:fiximages"] do
end


namespace :imageconvert do

require 'dragonfly'
require 'rack/cache'
app = Dragonfly[:images]

app.configure_with(:imagemagick)
app.configure_with(:rails)


  task :fiximages => :environment do
    count = 0

    Image.find_each do |image|
      count = count + 1 
      old_image = app.fetch(image.image_uid)
      image.file = old_image.file 
      image.file.meta.merge!(old_image.meta) 
      image.file = image.file 
      image.save! 
    end 

    puts "#{count} images processed"

  end

end


#require 'dragonfly'
#require 'rack/cache'


#app = Dragonfly[:images]

#app.configure_with(:imagemagick)
#app.configure_with(:rails)

#app.configure{|c|Dragonfly::ImageMagickUtils.convert_command = '/usr/local/bin/convert'}
#app.configure{|c|Dragonfly::ImageMagickUtils.identify_command = '/usr/local/bin/identify'}

#app.configure_with(:rails) do |c| 
#    c.datastore = Dragonfly::DataStorage::MongoDataStore.new(:database => 'thoughtdomains-db1') 
#end 
