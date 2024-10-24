require 'caracal/core/models/base_model'
require 'caracal/core/models/border_model'
require 'caracal/core/models/paragraph_model'
require 'caracal/core/models/has_background'
require 'caracal/core/models/has_color'
require 'caracal/core/models/has_borders'
require 'caracal/core/models/has_run_attributes'

module Caracal
  module Core
    module Models
      # This class handles block options passed to tables via their data collections.
      class TableCellModel < BaseModel
        use_prefix :cell

        include HasRunAttributes
        extend HasMargins

        has_margins #top: 100, left: 100, right: 100, bottom: 100

        has_string_attribute :style

        has_symbol_attribute :align          # paragraph attr
        has_symbol_attribute :content_vertical_align

        has_integer_attribute :colspan, default: 1
        has_integer_attribute :rowspan, default: 1
        has_integer_attribute :width

        attr_accessor :document, :table_ref

        # initialization
        def initialize(options={}, &block)
          @document            = options.delete :document
          @table_ref           = options.delete :table_ref
          @cell_rowspan        = DEFAULT_CELL_ROWSPAN
          @cell_colspan        = DEFAULT_CELL_COLSPAN
          @cell_top            = DEFAULT_CELL_TOP
          @cell_left           = DEFAULT_CELL_LEFT
          @cell_right          = DEFAULT_CELL_RIGHT
          @cell_bottom         = DEFAULT_CELL_BOTTOM
          @cell_content_vertical_align = DEFAULT_CELL_CONTENT_VERTICAL_ALIGN
          self.initialize_run_attributes

          make_content = false
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
              make_content = true
            end
          end

          super options, &block

          if make_content
            self.p content, self.paragraph_attributes.merge(self.run_attributes.to_h)
          else
            # the final tag in a table cell *must* be a paragraph for OOXML to not throw an error.
            p_klass = Caracal::Core::Models::ParagraphModel
            unless contents.last.is_a? p_klass
              self.contents << p_klass.new(self.paragraph_attributes.merge(self.run_attributes.to_h).merge content: '')
            end
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
        def apply_styles(opts={}, reverse: false)
          # make dup of options so we don't harm args sent to sibling cells
          options = opts.dup

          # first, try apply to self
          options.each do |k, v|
            if self.respond_to? k
              if not reverse or self.send("cell_#{k}").nil?
                send k, v
              end
              options.delete k if %i(top bottom left right).include? k.to_sym or k.to_s.include? 'border'
            end
          end

          # then, try apply to contents
          contents.each do |model|
            if model.respond_to? :apply_styles
              model.apply_styles options , reverse: reverse
            else
              pa = model.respond_to?(:paragraph_attributes) ? model.paragraph_attributes : {}
              options.each do |k, v|
                if model.respond_to? k and not pa[k]
                  model.send k, v
                  # options.delete k unless HasRunAttributes::ATTRS.include? k
                end
              end

              # finally, apply to runs. options do trickle down
              # because paragraph-level styles don't affect runs within tables.
              # only sets options on runs that don't have that option already set.
              if model.respond_to? :runs
                model.runs.each do |run|
                  ra = run.respond_to?(:run_attributes) ? run.run_attributes : {}
                  options.each do |k, v|
                    if run.respond_to? k and not ra[k]
                      run.send k, v
                    end
                  end
                end
              end
            end
          end
        end

        def relevant_cell_style(container)
          if self.cell_style
            @relevant_cell_style = container.find_style self.cell_style
          elsif container.table_style
            @relevant_cell_style = container.find_style container.table_style
          else
             # TODO: handle conditional styles! => determine relevant table styles based on this cell's grid position
          end
        end

        def calculate_width(default_width, container)
          # return unless self.cell_width.to_i > 0
          self.width default_width unless self.cell_width.to_i > 0

          # raise container.inspect # use to determine currently active style, then extract left and right
          l = self.cell_left  || relevant_cell_style(container)&.style_left || 0
          r = self.cell_right || relevant_cell_style(container)&.style_right || 0
          available_container_width = self.cell_width - l - r

          contents.each do |model|
            if model.respond_to? :calculate_width
              model.calculate_width available_container_width, container # FIXME: disabled for debugging
            end
          end
        end

        def find_style(*args)
          self.document.find_style *args
        end

        def paragraph_attributes
          {
            align: self.cell_align
          }.compact
        end

        def cnf_style(table_ref, row, col)
          current_table_style = document.find_style table_ref.table_style
          if current_table_style
            ConditionalFormat.new current_table_style, table_ref.table_look,
                row: row,
                col: col,
                rows: table_ref.rows.size,
                cols: table_ref.rows.map(&:size).max
          end
        end

        #=============== VALIDATION ===========================

        def valid?
          validate_size :width, at_least: 0, allow_nil: true and
              self.validate_inclusion :content_vertical_align, within: %i(top bottom center), allow_nil: true and
              self.valid_bgstyle? and
              self.validate('must at least contain one content element') { self.contents.size > 0 } and
              self.valid_run_attributes?
        end

        def self.option_keys
          @options_keys ||= [:style, :width, :align, :content_vertical_align, :rowspan, :colspan] +
              HasMargins::ATTRS +
              HasRunAttributes::ATTRS
        end

        private

        def option_keys
          self.class.option_keys
        end
      end

      class ConditionalFormat
        BITMASK = {
          firstRow:  0,
          lastRow:   0,
          firstCol:  0,
          lastCol:   0,
          band1Vert: 0,
          band2Vert: 0,
          band1Horz: 0,
          band2Horz: 0,
          neCell:    0,
          nwCell:    0,
          seCell:    0,
          swCell:    0
        }.freeze

        attr_reader :table_style

        def initialize(table_style, table_look, rows: nil, cols: nil, row: nil, col: nil)
          @table_style, @table_look = table_style, table_look
          @rows, @row, @cols, @col = rows, row, cols, col
          set_bitmask
        end

        def bitmask
          @bm.values.join ''
        end

        def style_hash
          hsh = @table_style.table_cell_style_attributes
          if @table_style.respond_to? :find_conditional_format
            {wholeTable: 1}.merge(@bm).each do |key, use|
              cf = @table_style.find_conditional_format key
              if use == 1 and cf
                hsh.merge! cf.table_cell_style_attributes
              end
            end
          end
          hsh
        end

        private

        def set_bitmask
          max_row = @rows - 1
          max_col = @cols - 1
          @bm = BITMASK.dup
          if @table_look.table_look_first_row and @row == 0
            @bm[:firstRow] = 1
            if @table_look.table_look_first_col and @col == 0
              @bm[:nwCell] = 1
            end
            if @table_look.table_look_last_col and @col == max_col
              @bm[:neCell] = 1
            end
          end

          if @table_look.table_look_last_row and @row == max_row
            @bm[:lastRow] = 1
            if @table_look.table_look_first_col and @col == 0
              @bm[:swCell] = 1
            end
            if @table_look.table_look_last_col and @col == max_col
              @bm[:seCell] = 1
            end
          end

          if @table_look.table_look_first_col and @col == 0
            @bm[:firstCol] = 1
          end

          if @table_look.table_look_last_col and @col == max_col
            @bm[:lastCol] = 1
          end

          # TODO: hband, vband
          @bm
        end
      end
    end
  end
end
