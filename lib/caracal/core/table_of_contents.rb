require 'caracal/core/models/table_of_content_model'
require 'caracal/errors'


module Caracal
  module Core

    # This module encapsulates all the functionality related to adding
    # table of contents to the document.
    #
    module TableOfContents
      def self.included(base)
        base.class_eval do

          #-------------------------------------------------------------
          # Public Methods
          #-------------------------------------------------------------

          def table_of_contents(options={}, &block)
            model = Caracal::Core::Models::TableOfContentModel.new(options, &block)
            unless model.valid?
              raise Caracal::Errors::InvalidModelError, \
                'Table of contents start_level and end_level must be between 0 and 6, \
                with end_level equal to or greater than start_level'
            end
            contents << model
            model
          end

          # Add an alias
          def toc(options={}, &block)
            table_of_contents(options, &block)
          end
        end
      end
    end

  end
end
