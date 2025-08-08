require 'caracal/core/models/base_model'
require 'caracal/core/models/border_model'
require 'caracal/core/models/table_cell_model'
require 'caracal/core/models/table_look_model'
require 'caracal/core/models/has_background'
require 'caracal/core/models/has_borders'

module Caracal
  module Core
    module Models

      # This class handles block options passed to the table
      # method.
      class TableModel < BaseModel
        use_prefix :table

        include HasBackground
        include HasBorders

        TABLE_LAYOUTS = %i(fixed autofit)
        TABLE_ALIGNS  = %i(left center right start end)

        has_string_attribute :caption
        has_string_attribute :style, default: 'TableNormal'

        has_symbol_attribute :layout, default: :fixed
        has_symbol_attribute :align, default: :center

        has_integer_attribute :repeat_header, default: 0
        has_integer_attribute :row_band_size, default: 1
        has_integer_attribute :col_band_size, default: 1
        has_integer_attribute :width
        has_integer_attribute :indent

        has_model_attribute :look,
            model: Caracal::Core::Models::TableLookModel,
            default: Caracal::Core::Models::TableLookModel.new

        # accessors
        attr_reader :table_column_widths
        attr_accessor :document

        # initialization
        def initialize(options={}, &block)
          @document             = options.delete :document
          @table_style          = DEFAULT_TABLE_STYLE
          @table_align          = DEFAULT_TABLE_ALIGN
          @table_repeat_header  = DEFAULT_TABLE_REPEAT_HEADER
          @table_row_band_size  = DEFAULT_TABLE_ROW_BAND_SIZE
          @table_col_band_size  = DEFAULT_TABLE_COL_BAND_SIZE
          @table_layout         = DEFAULT_TABLE_LAYOUT
          @table_look           = DEFAULT_TABLE_LOOK
          @table_border         = DEFAULT_TABLE_BORDER

          super options, &block
        end


        #-------------------------------------------------------------
        # Public Methods
        #-------------------------------------------------------------

        #=============== DATA ACCESSORS =======================

        def table_align
          case @table_align
          when :left
            :start
          when :right
            :end
          else
            @table_align
          end
        end

        def cells
          rows.flatten
        end

        def cols
          @cols ||= rows.reduce([]) do |array, row|
            row.each_with_index do |cell, index|
              array[index]  = []  if array[index].nil?
              array[index] << cell
            end
            array
          end
        end

        def rows
          @table_data || [[]]
        end


        #=============== STYLES ===============================

        # This method sets explicit widths on all wrapped cells
        # that do not already have widths asided.
        #
        def calculate_width(container_width, container)
          self.width container_width if self.table_width.to_i.zero?

          # now that we know the whole table's width, automatically calculate the cell's widths.
          self.cells.each { |c| c.calculate_width self.default_cell_width, self }
        end

        # This method allows tables to be styled several cells
        # at a time.
        #
        # For example, this would style a header row.
        #
        # docx.table data do |t|
        #   t.cell_style t.rows[0], bgcolor: '3366cc', color: 'ffffff', bold: true
        #   t.cell_style t.rows[2], style: 'MyTableRowStyle'
        # end
        #
        # where 'MyTableRowStyle' is a style with type 'table_row'
        #
        def cell_style(models, options={})
          # styles = merge_named_styles(options)

          [models].flatten.compact.each do |m|
            m.apply_styles options
          end
        end


        #=============== GETTERS ==============================

        def find_style(*args)
          self.document.find_style *args
        end


        #=============== SETTERS ==============================

        # column widths
        def column_widths(value)
          @table_column_widths = value.map &:to_i if value.is_a? Array
        end

        # .data
        def data(value)
          # begin
            @table_data = value.map do |data_row|
              data_row.map do |data_cell|
                cell = case data_cell
                when Caracal::Core::Models::TableCellModel
                  if data_cell.cell_style
                    # data_cell.apply_styles merge_named_styles(style: data_cell.cell_style)
                    # raise "should not happen (yet)"
                    data_cell.apply_styles # style: data_cell.cell_style
                  end
                  data_cell
                when Hash
                  # Caracal::Core::Models::TableCellModel.new merge_named_styles(data_cell)
                  Caracal::Core::Models::TableCellModel.new data_cell
                when Proc
                  Caracal::Core::Models::TableCellModel.new &data_cell
                else
                  Caracal::Core::Models::TableCellModel.new content: data_cell.to_s
                end

                cell.document  = self.document
                cell.table_ref = self
                cell
              end
            end
          #rescue
            #raise Caracal::Errors::InvalidTableDataError, 'Table data must be a two-dimensional array.'
          # end
        end

        #=============== VALIDATION ==============================

        def valid_align?
          validate_inclusion :align, within: TABLE_ALIGNS
        end

        def valid_layout?
          validate_inclusion :layout, within: TABLE_LAYOUTS
        end

        def valid?
          cells.all?{|c| c.nil? or c.is_a? Caracal::Core::Models::TableCellModel } and
              self.valid_bgstyle? and
              self.valid_align? and
              self.valid_layout?
        end

        private
        #
        # # FIXME: needs to be replaced with proper handling of multiple table styles
        # def merge_named_styles(options)
        #   named_style = options.delete :style
        #   if named_style
        #     raise "If you use cell styles, you must create the table using #table" unless @document
        #     ns = find_style named_style
        #     raise "style #{named_style} is not available in document" unless ns
        #     raise "style #{named_style} is a #{ns.style_type} but should be a table, table_cell, or table_row style" unless %i(table table_row table_cell).include?ns.style_type
        #     ns.to_h.merge options.compact
        #   else
        #     options.compact
        #   end
        # end

        # sums up all fixed cell widths, subtracts that from the total table with and divides it by the "flexible" cell count
        # this gives us the total space available per cell, *including* borders, spacings, paddings etc.
        def default_cell_width
          cell_widths     = self.rows.first.map { |c| c.cell_width.to_i }
          remaining_width = self.table_width - cell_widths.reduce(&:+).to_i
          remaining_cols  = cols.size - cell_widths.reject(&:zero?).size
          default_width   = remaining_cols.zero? ? 0 : (remaining_width / remaining_cols)
        end

        def option_keys
          k = []
          k << [:data, :align, :width, :style, :layout, :caption, :indent]
          k << HasBackground::ATTRS
          k << HasBorders::ATTRS
          k << [:column_widths]
          k << [:repeat_header, :row_band_size, :col_band_size]
          k.flatten
        end

      end

    end
  end
end
