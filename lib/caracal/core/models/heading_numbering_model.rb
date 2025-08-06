require 'ostruct'
require 'caracal/core/models/base_model'

module Caracal
  module Core
    module Models
      class HeadingNumberingModel < BaseModel
        use_prefix :heading_numbering

        attr_accessor :heading_numberings
        attr_accessor :id

        has_string_attribute :name, default: 'Caracal header numbering'

        FORMATS = %i(decimal lowerLetter upperLetter lowerRoman upperRoman)

        def initialize(options={}, &block)
          @id = options.delete :id
          @heading_numberings = options
          super({}, &block)
        end

        def h1(fmt: '', text: '', ilvl: 0, suff: 'space')
          heading_numberings[:h1].merge! fmt: fmt, lvl_text: text, ilvl: ilvl, style_id: 'Heading1', suff: suff
        end

        def h2(fmt: '', text: '', ilvl: 1, suff: 'space')
          heading_numberings[:h2].merge! fmt: fmt, lvl_text: text, ilvl: ilvl, style_id: 'Heading2', suff: suff
        end

        def h3(fmt: '', text: '', ilvl: 2, suff: 'space')
          heading_numberings[:h3].merge! fmt: fmt, lvl_text: text, ilvl: ilvl, style_id: 'Heading3', suff: suff
        end

        def h4(fmt: '', text: '', ilvl: 3, suff: 'space')
          heading_numberings[:h4].merge! fmt: fmt, lvl_text: text, ilvl: ilvl, style_id: 'Heading4', suff: suff
        end

        def h5(fmt: '', text: '', ilvl: 4, suff: 'space')
          heading_numberings[:h5].merge! fmt: fmt, lvl_text: text, ilvl: ilvl, style_id: 'Heading5', suff: suff
        end

        def h6(fmt: '', text: '', ilvl: 5, suff: 'space')
          heading_numberings[:h6].merge! fmt: fmt, lvl_text: text, ilvl: ilvl, style_id: 'Heading6', suff: suff
        end

        def to_h
          heading_numberings
        end

        private

        def option_keys
          [:h1, :h2, :h3, :h3, :h5, :h6]
        end
      end
    end
  end
end
