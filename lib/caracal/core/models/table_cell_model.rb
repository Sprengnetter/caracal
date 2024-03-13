require 'caracal/core/models/base_model'
require 'caracal/core/models/border_model'
require 'caracal/core/models/margin_model'
require 'caracal/core/models/paragraph_model'


module Caracal
  module Core
    module Models

      # This class handles block options passed to tables via their data
      # collections.
      #
      class TableCellModel < BaseModel
        use_prefix :cell

        has_string_attribute :background
        has_string_attribute :style
        has_string_attribute :border_color,    default: 'auto'

        has_symbol_attribute :vertical_align,  default: :top
        has_symbol_attribute :border_line,     default: :single

        has_integer_attribute :border_size,    default: 0 # in 1/8pt
        has_integer_attribute :border_spacing, default: 0 # in 1/8pt
        has_integer_attribute :colspan,        default: 1
        has_integer_attribute :rowspan,        default: 1
        has_integer_attribute :width

        has_model_attribute :margins,
            model: Caracal::Core::Models::MarginModel,
            default: Caracal::Core::Models::MarginModel.new(top: 100, bottom: 100, left: 100, right: 100)

        # accessors
        attr_reader :cell_border_top         # returns border model
        attr_reader :cell_border_bottom      # returns border model
        attr_reader :cell_border_left        # returns border model
        attr_reader :cell_border_right       # returns border model
        attr_reader :cell_border_horizontal  # returns border model
        attr_reader :cell_border_vertical    # returns border model

        # initialization
        def initialize(options={}, &block)
          @cell_rowspan        = DEFAULT_CELL_ROWSPAN
          @cell_colspan        = DEFAULT_CELL_COLSPAN
          @cell_background     = DEFAULT_CELL_BACKGROUND
          @cell_margins        = DEFAULT_CELL_MARGINS
          @cell_vertical_align = DEFAULT_CELL_VERTICAL_ALIGN
          @cell_border_color   = DEFAULT_CELL_BORDER_COLOR
          @cell_border_line    = DEFAULT_CELL_BORDER_LINE
          @cell_border_size    = DEFAULT_CELL_BORDER_SIZE
          @cell_border_spacing = DEFAULT_CELL_BORDER_SPACING

          if content = options.delete(:content)
            if content.is_a? BaseModel
              self.contents << content
            elsif content.is_a? Array
              content.each do |c|
                if c.is_a? BaseModel
                  self.contents << c
                else
                  raise "Content must be < Caracal::Core::Models::BaseModel but is #{content.inspect}"
                end
              end
            else
              p content, options.dup #, &block
            end
          end

          super options, &block

          p_klass = Caracal::Core::Models::ParagraphModel     # the final tag in a table cell
          unless contents.last.is_a? p_klass                  # *must* be a paragraph for OOXML
            contents << p_klass.new(content: '')              # to not throw an error.
          end
        end


        #-------------------------------------------------------------
        # Public Methods
        #-------------------------------------------------------------

        #=============== DATA ACCESSORS =======================

        def contents
          @contents ||= []
        end

        #=============== STYLES ===============================

        # This method allows styles to be applied to this cell
        # from the table level.  It attempts to add the style
        # first to the instance, and then to any sub-models that
        # respond to the method.
        #
        # In all cases, invalid options will simply be ignored.
        #
        def apply_styles(opts={})
          # make dup of options so we don't
          # harm args sent to sibling cells
          options = opts.dup

          # first, try apply to self
          options.each do |(k,v)|
            send(k, v) if respond_to?(k)
          end

          # prevent top-level attrs from trickling down
          options.delete_if { |(k,v)| option_keys.include?(k) }

          # then, try apply to contents
          contents.each do |model|
            options.each do |k,v|
              model.send(k, v) if model.respond_to?(k)
            end

            # finally, apply to runs. options do trickle down
            # because paragraph-level styles don't seem to
            # affect runs within tables. weirdsies.
            # only sets options on runs that don't have that option already set.
            if model.respond_to?(:runs)
              model.runs.each do |run|
                ra = run.respond_to?(:run_attributes) ? run.run_attributes : {}
                options.each do |k, v|
                  run.send(k, v) if run.respond_to?(k) and not ra[k]
                end
              end
            end
          end
        end

        def calculate_width(default_width)
          width(default_width) unless cell_width.to_i > 0

          container_width = cell_width - cell_margin_left - cell_margin_right

          contents.each do |model|
            if model.respond_to?(:calculate_width)
              model.calculate_width(container_width)    # will always be a TableModel
            end
          end
        end


        #=============== GETTERS ==============================

        # border attrs
        [:top, :bottom, :left, :right, :horizontal, :vertical].each do |m|
          [:color, :line, :size, :spacing].each do |attr|
            define_method "cell_border_#{ m }_#{ attr }" do
              model = send("cell_border_#{ m }")
              value = model ? model.send("border_#{ attr }") : send("cell_border_#{ attr }")
            end
          end

          define_method "cell_border_#{ m }_total_size" do
            model = send("cell_border_#{ m }")
            value = model ? model.total_size : cell_border_size + (2 * cell_border_spacing)
          end
        end

        # margin attrs
        [:top, :bottom, :left, :right].each do |m|
          define_method "cell_margin_#{ m }" do
            v = cell_margins ? cell_margins.send("margin_#{ m }") : 0
          end
        end


        #=============== SETTERS ==============================


        # models
        [:top, :bottom, :left, :right, :horizontal, :vertical].each do |m|
          define_method "border_#{m}" do |options = {}, &block|
            options.merge! type: m
            instance_variable_set "@cell_border_#{ m }", Caracal::Core::Models::BorderModel.new(options, &block)
          end

          [:color, :line, :size, :spacing].each do |a|
            define_method "border_#{m}_#{a}" do |v|
              model = instance_variable_get("@cell_border_#{m}") || instance_variable_set("@cell_border_#{m}", Caracal::Core::Models::BorderModel.new)

              model.send a, v
            end
          end
        end

        #=============== VALIDATION ===========================

        def valid?
          contents.size > 0
        end

        private

        def option_keys
          @options_keys ||= [:style, :background, :margins, :width, :vertical_align, :rowspan, :colspan,
           :border_color, :border_line, :border_size, :border_spacing,
           :border_bottom, :border_left, :border_right, :border_top, :border_horizontal, :border_vertical] +

            [:top, :bottom, :left, :right, :horizontal, :vertical].map do |b|
              [:color, :line, :size, :spacing].map do |a|
                :"border_#{b}_#{a}"
              end
            end.flatten
         end

      end

    end
  end
end
