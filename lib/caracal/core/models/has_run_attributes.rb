require 'caracal/core/models/has_background'
require 'caracal/core/models/has_color'
require 'caracal/core/models/has_borders'

module Caracal
  module Core
    module Models
      module HasRunAttributes

        OWN_ATTRS = [:font, :size, :bold, :italic, :underline, :caps, :small_caps, :strike, :rtl, :highlight_color, :vertical_align, :whitespace]
        ATTRS = OWN_ATTRS +
            HasBackground::ATTRS +
            HasColor::ATTRS +
            HasBorders::ATTRS

        VERTICAL_ALIGNS   = %i(subscript superscript baseline)

        def self.included(base)
          base.include HasBackground
          base.include HasColor
          base.include HasBorders

          base.has_string_attribute :font
          base.has_string_attribute :highlight_color

          base.has_symbol_attribute :vertical_align
          base.has_symbol_attribute :whitespace

          base.has_boolean_attribute :bold
          base.has_boolean_attribute :italic
          base.has_boolean_attribute :underline
          base.has_boolean_attribute :caps
          base.has_boolean_attribute :small_caps
          base.has_boolean_attribute :strike
          base.has_boolean_attribute :rtl

          base.has_integer_attribute :size
        end

        def run_attributes
          attrs = {
            font:            self.send("#{self.class.attr_prefix}_font"),
            color:           self.send("#{self.class.attr_prefix}_color"),
            highlight_color: self.send("#{self.class.attr_prefix}_highlight_color"),
            theme_color:     self.send("#{self.class.attr_prefix}_theme_color"),
            size:            self.send("#{self.class.attr_prefix}_size"),
            bold:            self.send("#{self.class.attr_prefix}_bold"),
            italic:          self.send("#{self.class.attr_prefix}_italic"),
            underline:       self.send("#{self.class.attr_prefix}_underline"),
            caps:            self.send("#{self.class.attr_prefix}_caps"),
            small_caps:      self.send("#{self.class.attr_prefix}_small_caps"),
            strike:          self.send("#{self.class.attr_prefix}_strike"),
            bgcolor:         self.send("#{self.class.attr_prefix}_bgcolor"),
            theme_bgcolor:   self.send("#{self.class.attr_prefix}_theme_bgcolor"),
            bgstyle:         self.send("#{self.class.attr_prefix}_bgstyle"),
            vertical_align:  self.send("#{self.class.attr_prefix}_vertical_align"),
            rtl:             self.send("#{self.class.attr_prefix}_rtl"),
          }.compact
          attrs[:hide_mark] = self.send("#{self.class.attr_prefix}_hide_mark") if self.respond_to? "#{self.class.attr_prefix}_hide_mark"
          OpenStruct.new attrs
        end

        private

        def valid_run_attributes?
          self.valid_whitespace? and self.valid_vertical_align? and self.valid_caps?
        end

        def valid_caps?
          if self.send("#{self.class.attr_prefix}_caps") and self.send("#{self.class.attr_prefix}_small_caps")
            self.errors << 'May have either caps or small caps but not both'
            false
          else
            true
          end
        end

        def valid_whitespace?
          validate_inclusion :whitespace, within: %i(preserve replace collapse), allow_nil: true
        end

        def valid_vertical_align?
          validate_inclusion :vertical_align, within: VERTICAL_ALIGNS, allow_nil: true
        end

        def initialize_run_attributes
          # so far, no defaults to be set here.
        end

      end
    end
  end
end
