require 'nokogiri'
require 'caracal/renderers/xml_renderer'
require 'caracal/renderers/render_helpers'
require 'caracal/errors'

module Caracal
  module Renderers
    class DocumentRenderer < XmlRenderer
      include RenderHelpers

      # This method produces the xml required for the `word/document.xml`
      # sub-document.
      def to_xml
        builder = ::Nokogiri::XML::Builder.with(declaration_xml) do |xml|
          w = xml['w']
          w.document root_options do
            w.body do
              #============= CONTENTS ===================================

              document.contents.each do |model|
                method = render_method_for_model(model)
                send(method, xml, model)
              end

              #============= PAGE SETTINGS ==============================

              w.sectPr do
                document.relationships_by_type(:header).each do |rel|
                  header = rel.owner
                  w.headerReference 'r:id' => rel.formatted_id, 'w:type' => (header.type || 'default')
                end

                document.relationships_by_type(:footer).each do |rel|
                  footer = rel.owner
                  w.footerReference 'r:id' => rel.formatted_id, 'w:type' => (footer.type || 'default')
                end

                w.pgSz page_size_options
                w.pgMar page_margin_options

                # FIXME: dirty hack to let word create a blank header for the first page which is the cover
                w.titlePg
              end

            end
          end
        end
        builder.to_xml save_options
      end

      private

      #============= COMMON RENDERERS ==========================

      # This method converts a model class name to a rendering
      # function on this class (e.g., Caracal::Core::Models::ParagraphModel
      # translates to `render_paragraph`).
      def render_method_for_model(model)
        type = model.class.name.split('::').last.downcase.gsub('model', '')
        "render_#{ type }"
      end


      #============= MODEL RENDERERS ===========================

      def render_rawxml(xml, model, **options)
        xml << model.to_s
      end

      def render_bookmark(xml, model, **options)
        if model.start?
          xml['w'].bookmarkStart 'w:id' => model.bookmark_id, 'w:name' => model.bookmark_name
        else
          xml['w'].bookmarkEnd 'w:id' => model.bookmark_id
        end
      end

      def render_iframe(xml, model, **options)
        ::Zip::File.open(model.file) do |zip|
          entry    = zip.glob('word/document.xml').first
          content  = entry.get_input_stream.read
          doc_xml  = Nokogiri::XML(content)
          ns       = document.namespaces
          fragment = doc_xml.xpath('//w:body').first.children

          fragment.pop

          model.relationships.each do |r_hash|
            id    = r_hash.delete(:id)              # we can't update the fragment until
            model = document.relationship(r_hash)   # the parent document assigns the embedded
            index = model.relationship_id           # relationship an id.

            r_node  = fragment.at_xpath("//a:blip[@r:embed='#{id}']", { a: ns.t('a'), r: ns.t('r') })
            if (r_attr = r_node.attributes['embed'])
              r_attr.value = "rId#{ index }"
            end

            p_parent = r_node.parent.parent
            p_node   = p_parent.children[0].children[0]
            if (p_attr = p_node.attributes['id'])
              p_attr.value = index.to_s
            end
          end

          xml << fragment.to_s
        end
      end

      def render_image_proper(xml, model, **options)
        rel      = document.relationship type: :image, target: model.image_url, data: model.image_data
        rel_id   = rel.relationship_id
        rel_name = rel.formatted_target

        xml['wp'].extent cx: model.formatted_width, cy: model.formatted_height
        xml['wp'].effectExtent t: 0, b: 0, r: 0, l: 0
        xml['wp'].wrapTopAndBottom if model.image_anchor

        xml['wp'].docPr id: rel_id, name: rel_name

        xml['wp'].cNvGraphicFramePr do
          xml['a'].graphicFrameLocks noChangeAspect: '1'
        end

        ns = document.namespaces

        xml['a'].graphic do
          xml['a'].graphicData uri: ns.t('pic') do
            xml['pic'].pic do
              xml['pic'].nvPicPr do
                xml['pic'].cNvPr id: rel_id, name: rel_name
                xml['pic'].cNvPicPr
              end
              xml['pic'].blipFill do
                xml['a'].blip 'r:embed' => rel.formatted_id
                xml['a'].srcRect
                xml['a'].stretch do
                  xml['a'].fillRect
                end
              end
              xml['pic'].spPr do
                xml['a'].xfrm do
                  xml['a'].ext cx: model.formatted_width, cy: model.formatted_height
                end
                xml['a'].prstGeom prst: 'rect'
                xml['a'].ln
              end
            end
          end
        end
      end

      def render_image(xml, model, **options)
        unless ds = document.default_style
          raise Caracal::Errors::NoDefaultStyleError 'Document must declare a default paragraph style.'
        end
        w = xml['w']

        w.p paragraph_options do
          w.pPr do
            w.spacing 'w:lineRule' => 'auto', 'w:line' => ds.style_line
            w.contextualSpacing 'w:val' => '0'
            w.jc 'w:val' => model.image_align.to_s
            w.rPr
          end

          w.r run_options do
            w.drawing do
              dist = {distR: model.formatted_right, distT: model.formatted_top, distB: model.formatted_bottom, distL: model.formatted_left}

              if model.image_anchor
                xml['wp'].anchor dist.merge(relativeHeight: false, simplePos: false, locked: true, layoutInCell: false, allowOverlap: false, behindDoc: false) do
                  xml['wp'].simplePos x: 0, y: 0
                  xml['wp'].positionH relativeFrom: 'page' do # TODO: allow other relativeFrom values
                    xml['wp'].align model.image_align
                  end
                  xml['wp'].positionV relativeFrom: 'page' do # TODO: allow other relativeFrom values
                    xml['wp'].align 'top'
                  end

                  render_image_proper xml, model
                end
              else
                xml['wp'].inline dist do
                  render_image_proper xml, model
                end
              end
            end
          end

          w.r run_options do
            w.rPr do
              # w.rtl 'w:val' => false
            end
          end
        end
      end

      def render_linebreak(xml, model, **options)
        w = xml['w']
        w.r do
          w.br
        end
      end

      def render_tableofcontent(xml, model, **options)
        w = xml['w']
        w.p paragraph_options do
          w.pPr do
            w.pStyle 'w:val' => 'TOCHeading'
            w.rPr
          end
          w.r do
            w.br 'w:type' => 'page'
          end
          w.r do
            w.t model.toc_legend
          end
        end

        fieldstart_rendered = false

        bookmarks_for(headings).each do |bookmark|
          next unless model.includes? bookmark[:level] # Skip levels outside the accepted range

          w.p paragraph_options do
            w.pPr do
              w.pStyle 'w:val' => "TOC#{bookmark[:level]}"
              w.tabs do
                w.tab 'w:val' => 'right', 'w:leader' => 'dot', 'w:pos' => '9486'
              end
            end

            unless fieldstart_rendered
              w.r do
                w.fldChar 'w:fldCharType' => 'begin'
              end
              w.r do
                w.instrText(
                  { 'xml:space' => 'preserve' },
                  " TOC \\o \"#{model.toc_start_level}-#{model.toc_end_level}\" \\h \\z \\u "
                )
              end
              w.r do
                w.fldChar 'w:fldCharType' => 'separate'
              end
              fieldstart_rendered = true
            end

            w.hyperlink 'w:anchor' => bookmark[:ref], 'w:history' => true do
              w.r do
                w.rPr do
                  w.rStyle 'w:val' => 'Hyperlink'
                end
                w.t bookmark[:text]
              end
              w.r do
                w.tab
              end
              w.r do
                w.fldChar 'w:fldCharType' => 'begin'
              end
              w.r do
                w.instrText(
                  { 'xml:space' => 'preserve' },
                  "  PAGEREF #{ bookmark[:ref] } \\h "
                )
              end
              w.r do
                w.fldChar 'w:fldCharType' => 'separate'
              end
              w.r do
                w.t '{bitte aktualisieren}' # fake number
              end
              w.r do
                w.fldChar 'w:fldCharType' => 'end'
              end
            end
          end
        end

        w.p paragraph_options do
          w.r do
            w.fldChar 'w:fldCharType' => 'end'
          end
        end
      end

      def render_link(xml, model, **options)
        w = xml['w']
        if model.external?
          rel = document.relationship target: model.link_href, type: :link
          hyperlink_options = { 'r:id' => rel.formatted_id }
        else
          hyperlink_options = { 'w:anchor' => model.link_href }
        end

        w.hyperlink(hyperlink_options) do
          w.r run_options do
            render_run_attributes xml, model, skip_empty: true
            w.t({ 'xml:space' => 'preserve' }, model.link_content)
          end
        end
      end

      def render_list(xml, model, **options)
        if model.list_level == 0
          document.toplevel_lists << model
          model.numbering_id = document.next_numbering_id
        end

        model.recursive_items.each do |item|
          render_listitem(xml, item, model.numbering_id)
        end
      end

      def render_listitem(xml, model, list_num, **options)
        ls      = document.find_list_style(model.list_item_type, model.list_item_level)
        hanging = ls.style_left.to_i - ls.style_indent.to_i - 1
        w = xml['w']

        w.p paragraph_options do
          w.pPr do
            w.pStyle 'w:val' => model.paragraph_style || 'Normal'
            w.keepNext if model.paragraph_keep_next == true
            w.numPr do
              w.ilvl 'w:val' => model.list_item_level
              w.numId 'w:val' => list_num
            end
            render_borders    w, model, 'pBdr', :paragraph
            render_background w, model, :paragraph
            render_tabs       w, model, model.paragraph_tabs if model.paragraph_tabs&.any?
            spacing = spacing_options model
            w.spacing spacing unless spacing.nil?
            w.ind 'w:start' => ls.style_left, 'w:hanging' => hanging
            w.contextualSpacing 'w:val' => true
            render_run_attributes w, model, skip_empty: true
          end

          model.runs.each do |run|
            method = render_method_for_model(run)
            send(method, xml, run)
          end
        end
      end

      def render_pagebreak(xml, model, **options)
        w = xml['w']
        if model.page_break_wrap
          w.p paragraph_options do
            w.r run_options do
              w.br 'w:type' => 'page'
            end
          end
        else
          w.r run_options do
            w.br 'w:type' => 'page'
          end
        end
      end

      def render_paragraph(xml, model, **options)
        w = xml['w']
        w.p paragraph_options do
          w.pPr do
            w.pStyle 'w:val' => model.paragraph_style || 'Normal'
            w.keepNext if model.paragraph_keep_next == true
            render_borders    w, model, 'pBdr', :paragraph
            render_background w, model, :paragraph
            render_tabs       w, model, model.paragraph_tabs if model.paragraph_tabs&.any?
            spacing = spacing_options model
            w.spacing spacing unless spacing.nil?
            w.ind               "w:#{model.indent[:side]}" => model.indent[:value] unless model.indent.nil?
            w.contextualSpacing 'w:val' => false
            w.jc                'w:val' => model.paragraph_align unless model.paragraph_align.nil?
            render_run_attributes xml, model, skip_empty: false
          end

          model.runs.each do |run|
            method = render_method_for_model(run)
            send(method, xml, run)
          end
        end
      end

      def render_rule(xml, model, **options)
        options = { 'w:color' => model.rule_color, 'w:sz' => model.rule_size, 'w:val' => model.rule_line, 'w:space' => model.rule_spacing }
        w = xml['w']

        w.p paragraph_options do
          w.pPr do
            w.pBdr do
              w.top options
            end
          end
        end
      end

      def render_text(xml, model, **options)
        return if model.text_content == '' and not model.text_end_tab
        w = xml['w']
        w.r run_options do
          render_run_attributes(xml, model, skip_empty: true)
          opts = {}
          opts['xml:space'] = model.text_whitespace || 'preserve'
          w.t opts, model.text_content
          w.tab if model.text_end_tab
        end
      end

      def render_field(xml, model, **options)
        w = xml['w']
        w.r run_options do
          render_run_attributes(xml, model, skip_empty: true)
          w.fldChar 'w:fldCharType' => 'begin'
          w.instrText 'xml:space' => 'preserve' do
            xml.text model.field_name
          end
          w.fldChar 'w:fldCharType' => 'end'
        end
      end

      def render_table(xml, model, **options)
        w = xml['w']
        tbl_look = table_look_options(model)

        unless model.table_caption.nil?
          w.p do
            w.pPr do
              w.pStyle 'w:val' => 'Caption'
              w.keepNext
            end
            w.r do
              w.t model.table_caption
            end
          end
        end

        w.tbl do
          w.tblPr do
            w.tblStyle            'w:val' => model.table_style || 'TableNormal'         #unless model.table_style.nil?
            # w.tblStyleRowBandSize 'w:val' => model.table_row_band_size unless model.table_row_band_size.nil?
            # w.tblStyleColBandSize 'w:val' => model.table_col_band_size unless model.table_col_band_size.nil?
            w.tblW                'w:w'   => model.table_width.to_i, 'w:type' => 'dxa' unless model.table_width.nil?
            w.jc                  'w:val' => model.table_align
            w.tblCellSpacing      'w:w'   => model.table_border_spacing, 'w:type' => 'dxa' unless model.table_border_spacing.nil?
            w.tblInd              'w:w'   => model.table_indent, 'w:type' => 'dxa' unless model.table_indent.nil?
            render_borders    w, model, 'tblBorders', :table
            render_background w, model, :table
            w.tblLayout           'w:type' => model.table_layout unless model.table_layout.nil?
            # w.tblCellMar 'w:w' => ..., type: 'dxa' # TODO
            w.tblLook             tbl_look unless tbl_look.nil?
            w.tblCaption          'w:val'  => model.table_caption unless model.table_caption.nil?
          end

          column_widths = model.table_column_widths
          w.tblGrid do
            column_widths ||= model.rows.first.map do |tc|
              if tc.cell_width
                [tc.cell_width] * (tc.cell_colspan || 1) # FIXME: this blatantly ignores defined column widths combined with merged cells!
              end
            end.flatten

            column_widths.each do |width|
              if width
                w.gridCol 'w:w' => width
              else
                w.gridCol
              end
            end
          end

          rowspan_hash = {} # stores the remaining rowspans per table cell index
          model.rows.each_with_index do |row, index|
            w.tr do
              w.trPr do
                if model.table_repeat_header > 0 and index < model.table_repeat_header
                  w.tblHeader
                end
                # w.cantSplit # to not split table cells across pages
                w.trHeight 'w:hRule' => 'auto'
                # w.tblCellSpacing 'w:w' => 0, 'w:type' => 'dxa'
              end

              row.each_with_index do |tc, tc_index| # NOTE: tc_index is modified inline at end of method!
                w.tc do
                  w.tcPr do
                    cnf_style = tc.cnf_style(model, index, tc_index)
                    # conditional styling rules
                    unless cnf_style.nil?
                      tc.apply_styles cnf_style.style_hash, reverse: true
                      w.cnfStyle 'w:val' => cnf_style.bitmask
                    end

                    # applying colspan
                    if tc.cell_colspan and tc.cell_colspan > 1
                      w.gridSpan 'w:val' => tc.cell_colspan
                    end

                    # applying rowspan
                    if tc.cell_rowspan and tc.cell_rowspan > 1 # start new cell with rowspan
                      rowspan_hash[tc_index] = tc.cell_rowspan - 1 # set rowspan info for next table rows: n-1 rows left to merge
                      w.vMerge 'w:val' => 'restart' # start new merged range
                    elsif rowspan_hash[tc_index] and rowspan_hash[tc_index] > 1 # before end of merged range
                      w.vMerge 'w:val' => 'continue' # continue merged range
                      rowspan_hash[tc_index] -= 1
                    elsif rowspan_hash[tc_index] == 1 # last cell in merged range
                      w.vMerge 'w:val' => 'continue'
                      rowspan_hash.delete tc_index # remove rowspan info, next row will not get vMerge
                    end

                    render_borders    w, tc, 'tcBorders', :cell
                    render_background w, tc, :cell
                    render_margins    w, tc, 'tcMar', :cell

                    # if column_widths[tc_index] and column_widths[tc_index] > 0
                    #   w.tcW 'w:w' => column_widths[tc_index], 'w:type' => 'auto'
                    # end

                    if tc.cell_content_vertical_align
                      w.vAlign 'w:val' => tc.cell_content_vertical_align
                    end
                  end

                  if tc.contents.any?
                    tc.contents.each do |table_cell_content|
                      method = render_method_for_model table_cell_content
                      send method, xml, table_cell_content, in_table: true
                    end
                  else # table cells ALWAYS need at least an empty paragraph
                    w.p do
                      w.r do
                        w.t ''
                      end
                    end
                  end
                end

                # adjust tc_index for next cell taking into account current cell's colspan
                tc_index += (tc.cell_colspan && tc.cell_colspan > 0) ? tc.cell_colspan : 1
              end
            end
          end
        end
      end

      #============= TABLE OF CONTENTS =========================

      # Returns all document headings (paragraphs with a style_id of HeadingX, X going from 1 to 6)
      def headings
        heading_styles = document.outline_styles.collect(&:style_id)
        document.contents.select do |model|
          model.respond_to?(:paragraph_style) && heading_styles.include?(model.paragraph_style) && !model.empty?
        end
      end

      # Returns a collection of hashes containing text, reference and level for the given models
      # TODO: allow listing figures and tables instead of only headings
      # TODO: allow limiting contents by section, as Word offers
      def bookmarks_for(headings)
        bookmarks = []
        headings.each do |heading|
          bookmarks << {
            ref:   bookmark_for(heading),
            text:  heading.plain_text,
            # outline levels in Word are zero-based, but we use 1-based levels within our models
            # this will be taken into account in the renderer
            level: heading.try(:paragraph_style).match(/Heading(\d)\Z/) { |m| m[1].to_i || 1 }
          }
        end
        bookmarks
      end

      # Returns the name (reference) of the first bookmark in the given model
      # Wraps the model contents in a bookmark if necessary
      def bookmark_for(model)
        if (run = model.runs.select { |run| run.is_a? Caracal::Core::Models::BookmarkModel }.first)
          run.bookmark_name
        else
          name = "_Toc#{ model.object_id }"
          model.runs.prepend(Caracal::Core::Models::BookmarkModel.new start: true, name: name, id: document.next_bookmark_id)
          model.runs.append(Caracal::Core::Models::BookmarkModel.new start: false, id: document.current_bookmark_id)
          name
        end
      end

      #============= OPTIONS ===================================

      def root_options
        opts = {}
        document.namespaces.each do |model|
          opts[model.namespace_prefix] = model.namespace_href
        end
        unless document.ignorables.empty?
          v = document.ignorables.join ' '
          opts['mc:Ignorable'] = v
        end
        opts
      end

      def page_margin_options
        {
          'w:top'    => document.page_margin_top,
          'w:bottom' => document.page_margin_bottom,
          'w:left'   => document.page_margin_left,
          'w:right'  => document.page_margin_right
        }
      end

      def page_size_options
        {
          'w:w'       => document.page_width,
          'w:h'       => document.page_height,
          'w:orient'  => document.page_orientation
        }
      end

      def table_look_options(model)
        return unless model.respond_to? :table_look
        opts = model.table_look

        val = 0
        val |= 0x0020 if opts.table_look_first_row
        val |= 0x0040 if opts.table_look_last_row
        val |= 0x0080 if opts.table_look_first_col
        val |= 0x0100 if opts.table_look_last_col
        val |= 0x0200 if opts.table_look_no_hband
        val |= 0x0400 if opts.table_look_no_vband
        {'w:val' => val.to_s(16).rjust(4, '0')}
      end

      def spacing_options(model)
        return unless model.respond_to? :spacing_options
        opts = model.spacing_options
        return if opts.all? &:nil?

        hsh = {}
        hsh['w:before'] = opts[:top].to_i    unless opts[:top].nil?
        hsh['w:after']  = opts[:bottom].to_i unless opts[:bottom].nil?
        hsh['w:line']   = opts[:line].to_i   unless opts[:line].nil?
        if hsh.empty?
          nil
        else
          hsh
        end
      end

      def render_tabs(w, tabs)
        w.tabs do
          tabs.each do |t|
            case t
            when Numeric
              w.tab 'w:val' => 'start', 'w:pos' => t.to_i, 'w:leader' => 'none'
            else
              w.tab 'w:val' => t[:val], 'w:pos' => t[:pos].to_i, 'w:leader' => (t[:leader] || 'none')
            end
          end
        end
      end
    end
  end
end
