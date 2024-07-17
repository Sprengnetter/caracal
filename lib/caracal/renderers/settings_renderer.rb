require 'nokogiri'

require 'caracal/renderers/xml_renderer'


module Caracal
  module Renderers
    class SettingsRenderer < XmlRenderer

      #-------------------------------------------------------------
      # Public Methods
      #-------------------------------------------------------------

      # This method produces the xml required for the `word/settings.xml`
      # sub-document.
      #
      def to_xml
        builder = ::Nokogiri::XML::Builder.with(declaration_xml) do |xml|
          w = xml['w']
          w.settings root_options do
            w.displayBackgroundShape 'w:val' => '1'
            w.defaultTabStop 'w:val' => '720'
            w.autoHyphenation 'w:val' => '1' # Automatically Hyphenate Document Contents When Displayed
            w.consecutiveHyphenLimit 'w:val' => 2 #    Maximum Number of Consecutively Hyphenated Lines
            w.compat do # see http://www.datypic.com/sc/ooxml/e-w_compat-1.html for options
              w.compatSetting 'w:val' => '14', 'w:name' => 'compatibilityMode', 'w:uri' => 'http://schemas.microsoft.com/office/word'
            end
            w.clrSchemeMapping 'w:bg1' => 'light1', 'w:t1' => 'dark1', 'w:bg2' => 'light2', 'w:t2' => 'dark2', 'w:accent1' => 'accent1', 'w:accent2' => 'accent2', 'w:accent3' => 'accent3', 'w:accent4' => 'accent4', 'w:accent5' => 'accent5', 'w:accent6' => 'accent6', 'w:hyperlink' => 'hyperlink', 'w:followedHyperlink' => 'followedHyperlink'
          end
        end
        builder.to_xml(save_options)
      end


      #-------------------------------------------------------------
      # Private Methods
      #-------------------------------------------------------------
      private

      def root_options
        {
          'xmlns:mc'   => 'http://schemas.openxmlformats.org/markup-compatibility/2006',
          'xmlns:o'    => 'urn:schemas-microsoft-com:office:office',
          'xmlns:r'    => 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
          'xmlns:m'    => 'http://schemas.openxmlformats.org/officeDocument/2006/math',
          'xmlns:v'    => 'urn:schemas-microsoft-com:vml',
          'xmlns:wp'   => 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
          'xmlns:w10'  => 'urn:schemas-microsoft-com:office:word',
          'xmlns:w'    => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
          'xmlns:wne'  => 'http://schemas.microsoft.com/office/word/2006/wordml',
          'xmlns:sl'   => 'http://schemas.openxmlformats.org/schemaLibrary/2006/main',
          'xmlns:a'    => 'http://schemas.openxmlformats.org/drawingml/2006/main',
          'xmlns:pic'  => 'http://schemas.openxmlformats.org/drawingml/2006/picture',
          'xmlns:c'    => 'http://schemas.openxmlformats.org/drawingml/2006/chart',
          'xmlns:lc'   => 'http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas',
          'xmlns:dgm'  => 'http://schemas.openxmlformats.org/drawingml/2006/diagram'
        }
      end

    end
  end
end
