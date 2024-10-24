require 'caracal/core/models/base_model'
require 'caracal/core/models/has_run_attributes'
require 'ostruct'

module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # text data.
      #
      class TextModel < BaseModel
        use_prefix :text

        include HasRunAttributes

        has_string_attribute :content
        has_string_attribute :style

        has_boolean_attribute :end_tab

        #========== GETTERS ===============================

        def run_attributes
          attrs = {
            style:            self.text_style,
            font:             self.text_font,
            color:            self.text_color,
            theme_color:      self.text_theme_color,
            size:             self.text_size,
            bold:             self.text_bold,
            italic:           self.text_italic,
            underline:        self.text_underline,
            caps:             self.text_caps,
            strike:           self.text_strike,
            small_caps:       self.text_small_caps,
            bgcolor:          self.text_bgcolor,
            theme_bgcolor:    self.text_theme_bgcolor,
            highlight_color:  self.text_highlight_color,
            vertical_align:   self.text_vertical_align,
            end_tab:          self.text_end_tab
          }.compact
          OpenStruct.new attrs
        end

        #========== VALIDATION ============================

        def valid?
          validate_presence :content, allow_empty: true and self.valid_run_attributes?
        end

        def self.option_keys
          [:content, :style, :end_tab] + HasRunAttributes::ATTRS
        end

        def apply_styles(opts={}, reverse: false)
          options = opts.dup
          ra = self.run_attributes
          options.each do |k, v|
            if self.respond_to? k and (reverse or not ra[k])
              self.send k, v
            end
          end
        end

        private

        def option_keys
          self.class.option_keys
        end
      end

    end
  end
end
