require 'RMagick' 
module Dragonfly 
  module Processing 
    class ImageProcessor
 
      include Dragonfly::RMagickUtils
      include Dragonfly::Configurable
      include Magick

      configurable_attr :use_filesystem, true

      def desat(temp_object, opts={})
        rmagick_image(temp_object) do |image| 
          image.quantize(2)
        end 
      end

      def negate(temp_object, opts={})
        rmagick_image(temp_object) do |image| 
          image.negate
        end
      end

      def watermark(temp_object, opts={})
        logo = ImageList.new(opts[:mark])
        rmagick_image(temp_object) do |image|
          image.watermark(logo)
        end
      end

    end 
  end 
end 
