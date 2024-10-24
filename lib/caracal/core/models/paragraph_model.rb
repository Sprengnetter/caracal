require 'caracal/core/models/base_model'
require 'caracal/core/models/bookmark_model'
require 'caracal/core/models/link_model'
require 'caracal/core/models/text_model'
require 'caracal/core/models/theme_color_model'
require 'caracal/core/models/has_margins'
require 'caracal/core/models/has_run_attributes'
require 'caracal/errors'
require 'ostruct'


module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # paragraph data.
      class ParagraphModel < BaseModel
        use_prefix :paragraph

        include HasRunAttributes
        extend HasMargins

        has_margins

        has_string_attribute :style

        has_symbol_attribute :align

        has_integer_attribute :line

        has_boolean_attribute :keep_next
        has_boolean_attribute :keep_lines
        has_boolean_attribute :widow_control
        has_boolean_attribute :hide_mark

        attr_reader :paragraph_tabs

        def initialize(options={}, &block)
          @indent = nil
          o = options.dup
          content = o.delete(:content) { '' }
          super o, &block

          # if there's content from the block, do not append an empty string content
          # otherwise make sure there is at least one (potentially empty) run
          if self.runs.none? or not content.to_s.strip.empty?
            text content, self.run_attributes
          end
        end


        #--------------------------------------------------
        # Public Instance Methods
        #--------------------------------------------------

        #========== GETTERS ===============================

        def runs
          @runs ||= []
        end

        def plain_text
          runs.collect { |run| run.try(:text_content).to_s }.join(' ').strip
        end

        def spacing_options
          {
            top:    self.paragraph_top,
            bottom: self.paragraph_bottom,
            line:   self.paragraph_line
          }
        end

        def paragraph_attributes
          {
            line:          self.paragraph_line,
            align:         self.paragraph_align,
            keep_next:     self.paragraph_keep_next,
            keep_lines:    self.paragraph_keep_lines,
            widow_control: self.paragraph_widow_control
          }.compact
        end

        #========== SETTERS ===============================

        # Getter/setter
        def indent(hash = nil)
          return @indent if hash.nil?

          unless [:left, :right].include?(hash.keys.first) && hash.values.first.is_a?(Integer)
            raise Caracal::Errors::InvalidModelError, 'the indent setter requires a hash like left: X or right: Y.'
          end

          @indent = { side: hash.keys.first, value: hash.values.first }
        end

        def tabs(values)
          @paragraph_tabs = values
        end

        #========== SUB-METHODS ===========================

        def field(*args, &block)
          options = self.run_attributes.to_h.except(:hide_mark)
          options.merge! Caracal::Utilities.extract_options!(args).dup
          options.merge! name: args.first if args.first

          model = Caracal::Core::Models::FieldModel.new options, &block
          if model.valid?
            runs << model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        # .bookmarks
        def bookmark_start(*args, &block)
          options = Caracal::Utilities.extract_options!(args).dup
          options.merge! start: true

          model = Caracal::Core::Models::BookmarkModel.new options, &block
          if model.valid?
            runs << model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        def bookmark_end(*args, &block)
          options = Caracal::Utilities.extract_options!(args).dup
          options.merge! start: false

          model = Caracal::Core::Models::BookmarkModel.new options, &block
          if model.valid?
            runs << model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        # .br
        def br
          model = Caracal::Core::Models::LineBreakModel.new
          runs << model
          model
        end

        # .link
        def link(*args, &block)
          options = self.run_attributes.to_h
          options.merge! Caracal::Utilities.extract_options!(args).dup
          options.merge! content: args[0] if args[0]
          options.merge! href:    args[1] if args[1]

          model = Caracal::Core::Models::LinkModel.new(options, &block)
          if model.valid?
            runs << model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        # .page
        def page
          model = Caracal::Core::Models::PageBreakModel.new wrap: false
          runs << model
          model
        end

        # .text
        def text(*args, &block)
          options = Caracal::Utilities.extract_options! args
          options.merge! self.run_attributes.to_h.except(:hide_mark)
          options.merge! content: args.first if args.first

          model = Caracal::Core::Models::TextModel.new(options, &block)
          if model.valid?
            runs << model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        #========== STATE =================================

        def empty?
          runs.size.zero? || plain_text.length.zero?
        end

        def apply_styles(opts={}, reverse: false)
          options = opts.dup
          pa = self.paragraph_attributes
          options.each do |k, v|
            if self.respond_to? k and (reverse or not pa[k])
              self.send k, v
              # options.delete k unless HasRunAttributes::ATTRS.include? k
            end
          end

          self.runs.each do |run|
            run.apply_styles options
          end
        end

        #========== VALIDATION ============================

        def valid?
          runs.any? and self.valid_bgstyle? and self.valid_run_attributes?
        end

        def self.option_keys
          %i[content style align tabs top bottom line keep_next keep_lines widow_control hide_mark] +
              HasMargins::ATTRS +
              HasRunAttributes::ATTRS
        end

        private

        def option_keys
          self.class.option_keys
        end

      end
    end
  end
end
