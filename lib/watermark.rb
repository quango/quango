#require 'RMagick' 

#module Dragonfly 
#  module Processing 
#    class Watermark
#      include Dragonfly::RMagickUtils 
#      include Dragonfly::Configurable 
#      configurable_attr :use_filesystem, true 
#        def add_watermark(temp_object, opts={}) 
#          path = opts[:path] 
#          src = Magick::Image.read(path).first 
#          rmagick_image(temp_object) do |image| 
#          image.composite(src, Magick::CenterGravity,Magick::OverCompositeOp) 
#          end 
#        end 
#    end
#  end 
#end 

