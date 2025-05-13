require 'caracal/core/models/bookmark_model'
require 'caracal/errors'


module Caracal
  module Core

    # This module encapsulates all the functionality related to adding
    # bookmarks to the document.
    #
    module Bookmarks
      def self.included(base)
        base.class_eval do
          #------------------------------------------------
          # Public Methods
          #------------------------------------------------

          def current_bookmark_id
            @current_bookmark_id ||= 1
          end

          def next_bookmark_id
            @current_bookmark_id = current_bookmark_id + 1
          end

          #========== BOOKMARKS ===========================

          def bookmark_start(*args, &block)
            options = Caracal::Utilities.extract_options!(args)
            options.merge!(start: true, id: next_bookmark_id)

            model = Caracal::Core::Models::BookmarkModel.new(options, &block)
            if model.valid?
              contents << model
            else
              raise Caracal::Errors::InvalidModelError, 'Bookmark starting tags require a name.'
            end
            model
          end

          def bookmark_end
            contents << Caracal::Core::Models::BookmarkModel.new(start: false, id: current_bookmark_id)
          end

        end
      end
    end

  end
end
