require 'caracal/core/models/text_model'


module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # link data.
      class LinkModel < TextModel
        use_prefix :link

        has_string_attribute :color, default: '1155cc'
        has_boolean_attribute :underline, default: true
        has_boolean_attribute :internal
        has_string_attribute :href

        # readers (create aliases for superclass methods to conform
        # to expected naming convention.)
        alias_method :link_content,         :text_content
        alias_method :link_font,            :text_font
        alias_method :link_color,           :text_color
        alias_method :link_size,            :text_size
        alias_method :link_bold,            :text_bold
        alias_method :link_italic,          :text_italic
        alias_method :link_underline,       :text_underline
        alias_method :link_bgcolor,         :text_bgcolor
        alias_method :link_highlight_color, :text_highlight_color
        alias_method :link_vertical_align,  :text_vertical_align

        # initialization
        def initialize(options={}, &block)
          @text_color     = DEFAULT_LINK_COLOR
          @text_underline = DEFAULT_LINK_UNDERLINE

          super options, &block
        end

        #========== STATE HELPERS =========================

        def external?
          !link_internal
        end

        #========== VALIDATION ============================

        def valid?
          a = [:content, :href]
          a.map { |m| send("link_#{ m }") }.compact.size == a.size
        end

        private

        def option_keys
          (super + [:internal, :href]).flatten
        end

      end
    end
  end
end
