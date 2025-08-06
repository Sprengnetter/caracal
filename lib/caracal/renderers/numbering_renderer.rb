require 'nokogiri'

require 'caracal/core/models/list_style_model'
require 'caracal/core/models/list_model'
require 'caracal/renderers/xml_renderer'


module Caracal
  module Renderers
    class NumberingRenderer < XmlRenderer
      # This method produces the xml required for the `word/numbering.xml` sub-document.
      def to_xml
        builder = ::Nokogiri::XML::Builder.with(declaration_xml) do |xml|
          w = xml['w']

          w.numbering root_options do
            document.with_header_numbering do |model|
              w.abstractNum 'w:abstractNumId' => model.id do
                w.multiLevelType 'w:val' => 'hybridMultilevel'
                w.name 'w:val' => model.heading_numbering_name

                model.heading_numberings.each do |header, num|
                  w.lvl 'w:ilvl' => num[:ilvl] do
                    w.start      'w:val' => 1
                    w.numFmt     'w:val' => num[:fmt]
                    # w.lvlRestart 'w:val' => 1 # default is: restart after next ower heading level is used
                    w.pStyle     'w:val' => num[:id]
                    w.suff       'w:val' => num[:suff]
                    w.lvlText    'w:val' => num[:lvl_text]
                    w.lvlJc      'w:val' => 'left'
                    w.pPr do
                      w.ind 'w:left' => 0, 'w:hanging' => 0
                    end
                  end
                end
              end
            end

            # add abstract numbering definitions
            document.toplevel_lists.each do |model|
              w.abstractNum 'w:abstractNumId' => model.numbering_id do
                w.multiLevelType 'w:val' => 'hybridMultilevel'
                model.level_map.each do |(level, type)|
                  if s = document.find_list_style(type, level)
                    w.lvl          'w:ilvl' => s.style_level do
                      w.start      'w:val' => s.style_start
                      w.numFmt     'w:val' => s.style_format
                      w.lvlRestart 'w:val' => s.style_restart
                      w.lvlText    'w:val' => s.style_value
                      w.lvlJc      'w:val' => s.style_align
                      w.pPr do
                        w.ind 'w:left' => s.style_left, 'w:firstLine' => s.style_indent
                      end
                      w.rPr do
                        w.u 'w:val' => 'none'
                      end
                    end
                  end
                end
              end
            end

            # bind concrete numberings to abstract definitions
            1.upto document.current_numbering_id do |i|
              w.num 'w:numId' => i do
                w.abstractNumId 'w:val' => i
              end
            end
          end
        end

        builder.to_xml(save_options)
      end

      private

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
