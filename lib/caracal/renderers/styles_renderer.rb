require 'nokogiri'
require 'caracal/renderers/xml_renderer'
require 'caracal/errors'
require 'caracal/renderers/render_helpers'

module Caracal
  module Renderers
    class StylesRenderer < XmlRenderer
      include RenderHelpers

      # This method produces the xml required for the `word/styles.xml`
      # sub-document.
      def to_xml
        builder = ::Nokogiri::XML::Builder.with(declaration_xml) do |xml|
          w = xml['w']
          w.styles root_options do
            #========== DEFAULT STYLES ====================

            unless s = document.default_style
              raise Caracal::Errors::NoDefaultStyleError 'Document must declare a default paragraph style.'
            end

            w.docDefaults do
              w.rPrDefault do
                render_run_attributes w, s, skip_empty: false
              end

              w.pPrDefault do
                w.pPr do
                  w.keepNext     'w:val' => s.style_keep_next     unless s.style_keep_next.nil?
                  w.keepLines    'w:val' => s.style_keep_lines    unless s.style_keep_lines.nil?
                  w.widowControl 'w:val' => s.style_widow_control unless s.style_widow_control.nil?
                  w.spacing spacing_options(s, true)
                  w.ind indentation_options(s, true)
                  w.jc           'w:val' => s.style_align         unless s.style_align.nil?
                end
              end
            end

            # w.latentStyles 'w:defLockedState' => 0, 'w:defPriority' => 99, 'w:defSemiHidden' => 1, 'w:defUnhideWhenUsed' => 1, 'w:defQFormat' => 0, 'w:count' => document.styles.size do
            #   document.styles.each do |model|
            #     w.lsdException 'w:name' => model.style_name, 'w:semiHidden' => 0, 'w:qFormat' => 1, 'w:priority' => 1, 'w:locked' => 0
            #   end
            # end

            # first, render the default paragraph and table styles. If no custom style is marked
            # as default, we render a fallback "Normal"/"TableNormal" style with no real style info.
            default_paragraph_style = document.styles.find{|s| s.style_type == :paragraph and s.style_default }
            default_table_style     = document.styles.find{|s| s.style_type == :table     and s.style_default }

            if default_paragraph_style
              render_paragraph_style w, default_paragraph_style
            else
              w.style 'w:styleId' => 'Normal', 'w:type' => 'paragraph', 'w:default' => true do
                w.name 'w:val' => 'normal'
              end
            end

            if default_table_style
              render_table_style w, default_table_style
            else
              w.style 'w:styleId' => 'TableNormal', 'w:type' => 'table', 'w:default' => true do
                w.name 'w:val' => 'Table Normal'
                w.pPr do
                  w.spacing 'w:lineRule' => 'exact', 'w:line' => (s.style_size * 20 * 1.15).to_i, 'w:before' => '0', 'w:after' => '0'
                end
              end
            end

            # render all user defined styles
            document.styles.each do |style|
              next if style.style_default
              case style.style_type
              when :paragraph, :character
                render_paragraph_style w, style
              when :table, :table_row
                render_table_style w, style
              when :table_cell
                render_table_cell_style w, style
              else
                raise "unknown style type: #{style.style_type}" # TODO: what about caracter/run styles?
              end
            end
          end
        end

        builder.to_xml save_options
      end

      private

      def render_table_cell_style(w, model)
        render_style w, model, 'table' do
          # run properties
          render_run_attributes w, model, skip_empty: true

          w.tblPr do
            w.jc             'w:val'  => model.style_align.to_s                      unless model.style_align.nil?
            w.tblCellSpacing 'w:w'    => model.style_cell_spacing, 'w:type' => 'dxa' unless model.style_cell_spacing.nil?

            render_borders    w, model, 'tcBorders', :style
            render_background w, model, :style
            render_margins    w, model, 'tblCellMar', :style
          end

          w.tcPr do
            render_background w, model, :style
            render_margins    w, model, 'tcMar', :style

            w.vAlign 'w:val' => model.style_content_vertical_align unless model.style_content_vertical_align.nil?
          end
        end
      end

      def render_style(w, model, type)
        style_opts = {'w:type' => type, 'w:styleId' => model.style_id}
        if model.style_default
          style_opts['w:default'] = '1'
        elsif not Document.default_styles.find{|s| s[:id] == model.style_id }
          style_opts['w:customStyle'] = '1'
        end

        w.style style_opts do
          w.name    'w:val' => model.style_name
          w.aliases 'w:val' => model.style_aliases unless model.style_aliases.nil?
          w.basedOn 'w:val' => model.style_base    unless model.style_base.nil?
          w.next    'w:val' => model.style_next    unless model.style_next.nil?
          w.locked if model.style_locked

          yield w, model
        end
      end

      def render_paragraph_style(w, model)
        spacing     = spacing_options model
        indentation = indentation_options model

        render_style w, model, 'paragraph' do
          # paragraph properties
          w.pPr do
            w.keepNext     'w:val' => model.style_keep_next     unless model.style_keep_next.nil?
            w.keepLines    'w:val' => model.style_keep_lines    unless model.style_keep_lines.nil?
            # w.pageBreakBefore # TODO: Start Paragraph on Next Page
            w.widowControl 'w:val' => model.style_widow_control unless model.style_widow_control.nil?
            render_borders    w, model, 'pBdr', :style
            render_background w, model, :style
            # w.tabs # TODO List of tabs
            # w.suppressAutoHyphens 'w:val' => false # TODO: Suppress Hyphenation for Paragraph
            w.wordWrap     'w:val' => model.style_word_wrap unless model.style_word_wrap.nil?
            # w.autoSpaceDE  'w:val' => 'true'
            w.spacing spacing unless spacing.nil?
            w.ind indentation unless indentation.nil?
            # w.contextualSpacing # TODO: Ignore Spacing Above and Below When Using Identical Styles
            w.jc            'w:val' => model.style_align.to_s       unless model.style_align.nil?
            w.outlineLvl    'w:val' => (model.style_outline_lvl - 1).to_s unless model.style_outline_lvl.nil?
          end

          # run properties
          render_run_attributes w, model, skip_empty: false
        end
      end

      def render_table_style(w, model)
        render_style w, model, 'table' do
          # paragraph properties
          w.pPr do
            w.jc 'w:val' => model.style_align.to_s unless model.style_align.nil?
          end

          # run properties
          render_run_attributes w, model, skip_empty: true

          # table properties
          w.tblPr do
            w.tblStyleRowBandSize 'w:val'  => model.style_row_band_size.to_i              unless model.style_row_band_size.nil?
            w.tblStyleColBandSize 'w:val'  => model.style_row_band_size.to_i              unless model.style_col_band_size.nil?
            # w.tblW                'w:w'    => 0, 'w:type' => 'auto' # Preferred Table Width
            w.jc                  'w:val'  => model.style_align.to_s                      unless model.style_align.nil?
            w.tblCellSpacing      'w:w'    => model.style_cell_spacing, 'w:type' => 'dxa' unless model.style_cell_spacing.nil?
            w.tblInd              'w:w'    => model.style_indent_left.to_i                unless model.style_indent_left.nil?
            render_borders    w, model, 'tblBorders', :style
            render_background w, model, :style
            render_margins    w, model, 'tblCellMar', :style
          end

          # tabe cell properties
          w.tcPr do
            render_background w, model, :style
          end

          # only applies to table row styles
          # w.trPr do
            # w.cantSplit 'w:val' => '1'
            # w.tblHeader
            ##w:cnfStyle [0..1]     Table Row Conditional Formatting
            ##w:divId [0..1]        Associated HTML div ID
            ##w:gridBefore [0..1]   Grid Columns Before First Cell
            ##w:gridAfter [0..1]    Grid Columns After Last Cell
            ##w:wBefore [0..1]      Preferred Width Before Table Row
            ##w:wAfter [0..1]       Preferred Width After Table Row
            ##w:cantSplit [0..1]    Table Row Cannot Break Across Pages
            ##w:trHeight [0..1]     Table Row Height
            ##w:tblHeader [0..1]    Repeat Table Row on Every New Page
            #w.tblCellSpacing(spacing_options(s)) unless spacing_options(s).nil?
            #w.jc('w:val' => model.style_align.to_s) unless model.style_align.nil?
            ##w:hidden [0..1]       Hidden Table Row Marker
          # end

          if model.conditional_formats
            # conditional formatting
            model.conditional_formats.each do |cf|
              w.tblStylePr 'w:type' => cf.style_type do
                unless model.style_align.nil?
                  # NOTE: setting any other pPr here would have no effect.
                  w.pPr do
                    w.jc 'w:val' => model.style_align.to_s
                  end
                end

                # run properties
                render_run_attributes w, cf, skip_empty: true

                # table cell properties
                w.tcPr do
                  render_borders    w, cf, 'tcBorders', :style
                  render_background w, cf, :style
                  render_margins    w, cf, 'tcMar', :style
                  w.vAlign 'w:val' => cf.style_content_vertical_align unless model.style_content_vertical_align.nil?
                end
              end
            end
          end

        end
      end

      def indentation_options(model, default = false)
        left    = default ? model.style_indent_left.to_i  : model.style_indent_left
        right   = default ? model.style_indent_right.to_i : model.style_indent_right
        first   = default ? model.style_indent_first.to_i : model.style_indent_first
        options = nil
        if [left, right, first].compact.size > 0
          options                = {}
          options['w:start']     = left  unless left.nil?
          options['w:end']       = right unless right.nil?
          options['w:firstLine'] = first unless first.nil?
        end
        options
      end

      def spacing_options(model, default=false)
        top     = default ? model.style_top.to_i    : model.style_top
        bottom  = default ? model.style_bottom.to_i : model.style_bottom
        line    = model.style_line
        options = nil

        if [top, bottom, line].compact.size > 0
          options               = {}
          options['w:lineRule'] = model.style_line_rule unless model.style_line_rule.nil?
          options['w:before']   = top                   unless top.nil?
          options['w:after']    = bottom                unless bottom.nil?
          options['w:line']     = line                  unless line.nil?
          options['w:afterAutospacing']  = model.style_before_autospacing unless model.style_before_autospacing.nil?
          options['w:beforeAutospacing'] = model.style_after_autospacing  unless model.style_after_autospacing.nil?
        end

        options
      end

      def root_options
        {
          'xmlns:mc'  => 'http://schemas.openxmlformats.org/markup-compatibility/2006',
          'xmlns:o'   => 'urn:schemas-microsoft-com:office:office',
          'xmlns:r'   => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
          'xmlns:m'   => 'http://schemas.openxmlformats.org/officeDocument/2006/math',
          'xmlns:v'   => 'urn:schemas-microsoft-com:vml',
          'xmlns:wp'  => 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
          'xmlns:w10' => 'urn:schemas-microsoft-com:office:word',
          'xmlns:w'   => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
          'xmlns:wne' => 'http://schemas.microsoft.com/office/word/2006/wordml',
          'xmlns:sl'  => 'http://schemas.openxmlformats.org/schemaLibrary/2006/main',
          'xmlns:a'   => 'http://schemas.openxmlformats.org/drawingml/2006/main',
          'xmlns:pic' => 'http://schemas.openxmlformats.org/drawingml/2006/picture',
          'xmlns:c'   => 'http://schemas.openxmlformats.org/drawingml/2006/chart',
          'xmlns:lc'  => 'http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas',
          'xmlns:dgm' => 'http://schemas.openxmlformats.org/drawingml/2006/diagram'
        }
      end

    end
  end
end
