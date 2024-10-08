require 'caracal/core/models/style_model'
require 'caracal/core/models/table_style_model'
require 'caracal/errors'

module Caracal
  module Core

    # This module encapsulates all the functionality related to defining
    # paragraph styles.
    #
    module Styles
      def self.included(base)
        base.class_eval do

          #-------------------------------------------------------------
          # Class Methods
          #-------------------------------------------------------------

          def self.default_styles
            [
              { id: 'Normal',    name: 'normal',    font: 'Arial',    size: 20, line: 320, color: '333333', default: true, type: :paragraph },
              { id: 'Header',    name: 'header',    font: 'Arial',    size: 20, bottom: 120, type: :paragraph },
              { id: 'Footer',    name: 'footer',    font: 'Arial',    size: 20, bottom: 120, type: :paragraph },
              { id: 'Heading1',  name: 'heading 1', font: 'Palatino', size: 36, bottom: 120, type: :paragraph },
              { id: 'Heading2',  name: 'heading 2', font: 'Arial',    size: 26, bottom: 120, top: 120, bold: true, type: :paragraph },
              { id: 'Heading3',  name: 'heading 3', font: 'Arial',    size: 24, bottom: 120, top: 120, bold: true, italic: true, color: '666666', type: :paragraph },
              { id: 'Heading4',  name: 'heading 4', font: 'Palatino', size: 24, bottom: 120, top: 120, bold: true, type: :paragraph },
              { id: 'Heading5',  name: 'heading 5', font: 'Arial',    size: 22, bottom: 120, top: 120, bold: true, type: :paragraph },
              { id: 'Heading6',  name: 'heading 6', font: 'Arial',    size: 22, bottom: 120, top: 120, underline: true, italic: true, color: '666666', type: :paragraph },
              { id: 'TOC1',      name: 'TOC 1',     font: 'Palatino', size: 22, bottom: 120, top: 120, indent_left:   0, bold: true, type: :paragraph },
              { id: 'TOC2',      name: 'TOC 2',     font: 'Arial',    size: 22, bottom: 120, top: 120, indent_left:  60, type: :paragraph },
              { id: 'TOC3',      name: 'TOC 3',     font: 'Arial',    size: 22, bottom: 120, top: 120, indent_left: 120, type: :paragraph },
              { id: 'TOC4',      name: 'TOC 4',     font: 'Palatino', size: 22, bottom: 120, top: 120, indent_left: 180, italic: true, color: '666666', type: :paragraph },
              { id: 'TOC5',      name: 'TOC 5',     font: 'Arial',    size: 22, bottom: 120, top: 120, indent_left: 240, italic: true, color: '666666', type: :paragraph },
              { id: 'TOC6',      name: 'TOC 6',     font: 'Arial',    size: 22, bottom: 120, top: 120, indent_left: 320, italic: true, color: '666666', type: :paragraph },
              { id: 'Title',     name: 'title',     font: 'Palatino', size: 60 },
              { id: 'Subtitle',  name: 'subtitle',  font: 'Arial',    size: 28, top: 60 },
              { id: 'Caption',   name: 'caption',   font: 'Arial',    size: 22, bottom: 120, top: 120, bold: true, type: :paragraph  },
              { id: 'Hyperlink', name: 'hyperlink', type: 'character', underline: true, color: '0000ff' }
            ]
          end


          #-------------------------------------------------------------
          # Public Methods
          #-------------------------------------------------------------

          #============== ATTRIBUTES ==========================

          def style(options={}, &block)
            if %(table table_row table_cell).include? options[:type].to_s
              model = Caracal::Core::Models::TableStyleModel.new(options, &block)
            else
              model = Caracal::Core::Models::StyleModel.new(options, &block)
            end
            # raise model.inspect if model.style_id == 'TableHeading'

            if model.valid?
              register_style model
            else
              raise Caracal::Errors::InvalidModelError, model.errors.inspect
            end
            model
          end

          #============== GETTERS =============================

          def styles
            @styles ||= []
          end

          def outline_styles
            @outline_styles ||= styles.select { |style| !style.style_outline_lvl.nil? }
          end

          def default_style
            styles.find { |s| s.style_default }
          end

          def find_style(id)
            styles.find { |s| s.matches?(id) }
          end


          #============== REGISTRATION ========================

          def register_style(model)
            unregister_style(model.style_id)
            styles << model
            model
          end

          def unregister_style(id)
            if s = find_style(id)
              styles.delete(s)
            end
          end

        end
      end
    end

  end
end
