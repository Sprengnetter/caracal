require 'caracal/core/models/style_model'

module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # table style data and conditional formating.
      class TableStyleModel < StyleModel
        CONDITIONAL_FORMAT_TYPES = %i(wholeTable band1Horz band1Vert band2Horz band2Vert firstCol firstRow lastCol lastRow neCell nwCell seCell swCell)
        CONTENT_VERTICAL_ALIGNS  = %i(top center bottom)

        DEFAULT_STYLE_TYPE = :table
        DEFAULT_STYLE_BASE = 'TableNormal'

        use_prefix :style

        has_integer_attribute :col_band_size, default: 1
        has_integer_attribute :row_band_size, default: 1
        has_integer_attribute :cell_spacing

        has_symbol_attribute :content_vertical_align#, default: :top

        def initialize(options = {}, &block)
          @_conditional                 = options.delete :conditional
          @style_default                = false
          @conditional_formats          = nil
          @style_col_band_size          = DEFAULT_STYLE_COL_BAND_SIZE
          @style_row_band_size          = DEFAULT_STYLE_ROW_BAND_SIZE
          @style_cell_spacing           = DEFAULT_STYLE_CELL_SPACING
          @style_content_vertical_align = DEFAULT_STYLE_CONTENT_VERTICAL_ALIGN
          # @style_margins                = DEFAULT_STYLE_MARGINS
          super options, &block
        end

        def conditional_format(options, &block)
          @conditional_formats ||= {}
          model = Caracal::Core::Models::TableStyleModel.new options.merge(conditional: true), &block
          if model.valid?
            @conditional_formats[options[:type]] = model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
        end

        def conditional_formats
          @conditional_formats&.values
        end

        def find_conditional_format(name)
          @conditional_formats[name.to_s]
        end

        def run_attributes
          attrs = {
            font:            self.style_font,
            color:           self.style_color,
            theme_color:     self.style_theme_color,
            size:            self.style_size,
            bold:            self.style_bold,
            italic:          self.style_italic,
            underline:       self.style_underline,
            caps:            self.style_caps,
            small_caps:      self.style_small_caps,
            vertical_align:  self.style_vertical_align,
            # highlight_color: self.style_highlight_color
          }.compact
          OpenStruct.new attrs
        end

        # attributes that cannot be set via table styles and have to be set for each cell separately.
        def table_cell_style_attributes
          hsh = super
          %i(content_vertical_align).inject({}) do |h, k|
            v = self.send "#{self.class.attr_prefix}_#{k}"
            hsh[k] = v unless v.nil?
          end
          hsh
        end

        def valid_type?
          if @_conditional
            validate_inclusion :type, within: CONDITIONAL_FORMAT_TYPES
          else
            super
          end
        end

        def valid?
          super #and validate_all :conditional_formats, allow_nil: true
        end
      end

    end
  end
end
