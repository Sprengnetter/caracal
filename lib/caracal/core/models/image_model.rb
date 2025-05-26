require 'caracal/core/models/base_model'


module Caracal
  module Core
    module Models

      # This class handles block options passed to the img method.
      #
      class ImageModel < BaseModel
        use_prefix :image

        has_integer_attribute :ppi,    default: 72 # pixels per inch
        has_integer_attribute :width,  default: 0  # units in pixels. (will cause error)
        has_integer_attribute :height, default: 0  # units in pixels. (will cause error)
        has_integer_attribute :top,    default: 8  # units in pixels.
        has_integer_attribute :bottom, default: 8  # units in pixels.
        has_integer_attribute :left,   default: 8  # units in pixels.
        has_integer_attribute :right,  default: 8  # units in pixels.

        has_symbol_attribute :align, default: :left
        has_symbol_attribute :anchor

        has_string_attribute :url
        has_string_attribute :data

        # initialization
        def initialize(options={}, &block)
          @image_ppi    = DEFAULT_IMAGE_PPI
          @image_width  = DEFAULT_IMAGE_WIDTH
          @image_height = DEFAULT_IMAGE_HEIGHT
          @image_align  = DEFAULT_IMAGE_ALIGN
          @image_top    = DEFAULT_IMAGE_TOP
          @image_bottom = DEFAULT_IMAGE_BOTTOM
          @image_left   = DEFAULT_IMAGE_LEFT
          @image_right  = DEFAULT_IMAGE_RIGHT
          @image_anchor = DEFAULT_IMAGE_ANCHOR

          super(options, &block).tap do
            formatted_width
            formatted_height
          end
        end

        #=============== GETTERS ==============================

        [:width, :height].each do |m|
          define_method "formatted_#{m}" do
            value = send("image_#{m}")
            instance_variable_get "@cached_image_#{m}" or instance_variable_set "@cached_image_#{m}", pixels_to_emus(value, image_ppi)
          end
        end

        [:top, :bottom, :left, :right].each do |m|
          define_method "formatted_#{m}" do
            value = send("image_#{m}")
            pixels_to_emus(value, 72) # NOT image_ppi!
          end
        end

        #=============== SETTERS ==============================

        def anchor(value)
          if value
            @image_anchor = value.to_s.to_sym
          else
            @image_anchor = nil
          end
        end

        #=============== VALIDATION ==============================

        def valid?
          [:ppi, :width, :height, :top, :bottom, :left, :right].all? {|a| validate_size a, at_least: 0 }
        end

        private

        def option_keys
          [:url, :width, :height, :align, :top, :bottom, :left, :right, :data, :anchor]
        end

        def pixels_to_emus(value, ppi)
          pixels        = value.to_i
          inches        = pixels / ppi.to_f
          emus_per_inch = 914400

          emus = (inches * emus_per_inch).to_i
        end

      end

    end
  end
end
