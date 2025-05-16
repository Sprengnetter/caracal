require 'ostruct'
require 'caracal/core/models/base_model'
require 'caracal/core/models/has_margins'
require 'caracal/core/models/has_run_attributes'


module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # paragraph style data.
      class StyleModel < BaseModel
        use_prefix :style

        include HasRunAttributes
        extend HasMargins

        has_margins

        has_string_attribute :id
        has_string_attribute :name
        has_string_attribute :aliases
        has_string_attribute :base, default: 'Normal'
        has_string_attribute :next, default: 'Normal'

        has_integer_attribute :line, default: 360 # 0.25in in twips
        has_integer_attribute :indent_left  # twips
        has_integer_attribute :indent_right # twips
        has_integer_attribute :indent_first # twips

        has_boolean_attribute :default, default: false
        has_boolean_attribute :keep_next
        has_boolean_attribute :keep_lines
        has_boolean_attribute :widow_control
        has_boolean_attribute :word_wrap
        has_boolean_attribute :locked
        has_boolean_attribute :before_autospacing, default: false
        has_boolean_attribute :after_autospacing, default: false

        has_symbol_attribute :line_rule, default: :exact
        has_symbol_attribute :type, default: :paragraph
        has_symbol_attribute :align, default: :left

        TYPES             = %i(character paragraph table table_row table_cell)
        HORIZONTAL_ALIGNS = %i(left center right both)
        LINE_RULES        = %i(exact auto atLeast)

        # initialization
        def initialize(options={}, &block)
          super options, &block

          if self.style_id == self.class::DEFAULT_STYLE_BASE
            @style_default = true
            @style_base    = nil
          else
            @style_default = false
            @style_base    ||= DEFAULT_STYLE_BASE
          end

          @style_type      ||= DEFAULT_STYLE_TYPE
          @style_next      = DEFAULT_STYLE_NEXT
          @style_top       ||= DEFAULT_STYLE_TOP
          @style_bottom    ||= DEFAULT_STYLE_BOTTOM
          @style_left      ||= DEFAULT_STYLE_LEFT
          @style_right     ||= DEFAULT_STYLE_RIGHT
          @style_line      ||= DEFAULT_STYLE_LINE
          @style_line_rule ||= DEFAULT_STYLE_LINE_RULE
          @style_word_wrap ||= DEFAULT_STYLE_WORD_WRAP

          # raise options.inspect if self.style_type.to_s == 'table'
        end


        #========== GETTERS ===============================

        def style_outline_lvl
          # outline levels in Word are zero-based, but we use 1-based levels within our models
          # this will be taken into account in the renderer
          style_id.match(/Heading(\d)\Z/) {|match| match[1].to_i}
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
            bgcolor:         self.style_bgcolor,
            theme_bgcolor:   self.style_theme_bgcolor,
            bgstyle:         self.style_bgstyle,
            vertical_align:  self.style_vertical_align,
            # highlight_color: self.style_highlight_color
          }.compact
          OpenStruct.new attrs
        end


        #========== STATE =================================

        def matches?(str)
          style_id.downcase == str.to_s.downcase
        end

        #========== VALIDATION ============================

        def valid?
          validate_presence :id and
              validate_presence :name and
              validate_presence :type and
              self.valid_type? and
              validate_inclusion :align, within: HORIZONTAL_ALIGNS and
              validate_inclusion :line_rule, within: LINE_RULES and
              self.valid_bgstyle? and
              self.valid_run_attributes?
        end

        def valid_type?
          validate_inclusion :type, within: TYPES
        end

        def to_h
          option_keys.inject({}) do |h, k|
            v = self.send "#{self.class.attr_prefix}_#{k}"
            h[k] = v unless v.nil?
            h
          end
        end

        # attributes that cannot be set via table styles and have to be set for each cell separately.
        def table_cell_style_attributes
          (%i(line line_rule align word_wrap keep_lines keep_next font size) + HasMargins::ATTRS + HasRunAttributes::OWN_ATTRS + HasColor::ATTRS).inject({}) do |h, k|
            v = self.send "#{self.class.attr_prefix}_#{k}"
            h[k] = v unless v.nil?
            h
          end
        end

        private

        def option_keys
          [:aliases, :type, :base, :line, :line_rule, :id, :name, :align, :widow_control, :word_wrap, :keep_lines, :keep_next, :locked] +
              HasMargins::ATTRS +
              HasRunAttributes::ATTRS +
              %w(left right first).map{|b| :"indent_#{b}" }
        end

      end

    end
  end
end
