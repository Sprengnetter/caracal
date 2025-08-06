require 'caracal/core/models/heading_numbering_model'
require 'caracal/errors'

module Caracal
  module Core
    module HeadingNumbering
      def self.included(base)
        base.class_eval do
          def default_heading_numberings
            {
              h1: { style_id: 'Heading1', fmt: 'none', lvl_text: '', ilvl: 0, suff: 'nothing' },
              h2: { style_id: 'Heading2', fmt: 'none', lvl_text: '', ilvl: 1, suff: 'nothing' },
              h3: { style_id: 'Heading3', fmt: 'none', lvl_text: '', ilvl: 2, suff: 'nothing' },
              h4: { style_id: 'Heading4', fmt: 'none', lvl_text: '', ilvl: 3, suff: 'nothing' },
              h5: { style_id: 'Heading5', fmt: 'none', lvl_text: '', ilvl: 4, suff: 'nothing' },
              h6: { style_id: 'Heading6', fmt: 'none', lvl_text: '', ilvl: 5, suff: 'nothing' },
            }
          end

          def heading_numbering(options={}, &block)
            model = Caracal::Core::Models::HeadingNumberingModel.new self.default_heading_numberings.deep_merge(options), &block
            if model.valid?
              @heading_numbering = model
            else
              raise Caracal::Errors::InvalidModelError, model.errors.inspect
            end
            model
          end

          def heading_numbering?
            !!@heading_numbering
          end

          def with_header_numbering
            yield @heading_numbering if heading_numbering?
          end

        end
      end
    end

  end
end
