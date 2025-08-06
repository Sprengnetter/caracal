require 'caracal/core/models/base_model'
require 'caracal/core/models/list_item_model'
require 'caracal/errors'


module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # list data.
      #
      class ListModel < BaseModel
        attr_accessor :numbering_id # identifies the abstract numbering scheme. Set during document rendering.

        use_prefix :list

        has_symbol_attribute :type, default: :unordered
        has_integer_attribute :level, default: 0

        # initialization
        def initialize(options={}, &block)
          @list_type  = DEFAULT_LIST_TYPE
          @list_level = DEFAULT_LIST_LEVEL

          super options, &block
        end

        #=============== GETTERS ==============================

        # This method returns only those items owned directly
        # by this list.
        def items
          @items ||= []
        end

        # This method returns a hash, where the keys are levels
        # and the values are the list type at that level.
        def level_map
          recursive_items.reduce({}) do |hash, item|
            hash[item.list_item_level] = item.list_item_type
            hash
          end
        end

        # This method returns a flattened array containing every
        # item within this list's tree.
        def recursive_items
          items.map do |model|
            if model.nested_list.nil?
              model
            else
              [model, model.nested_list.recursive_items]
            end
          end.flatten
        end

        #=============== SUB-METHODS ===========================

        # .li
        def li(*args, &block)
          options = Caracal::Utilities.extract_options! args
          options.merge! content: args.first if args.first
          options.merge! type: list_type, level: list_level

          model = Caracal::Core::Models::ListItemModel.new options, &block
          if model.valid?
            items << model
          else
            raise Caracal::Errors::InvalidModelError, 'List item must have at least one run.'
          end
          model
        end


        def apply_styles(opts={}, reverse: false)
          self.items.each do |item|
            item.apply_styles opts, reverse: reverse
          end
        end

        #=============== VALIDATION ===========================

        def valid?
          [:type, :level].all? {|a| validate_presence a } and not items.empty?
        end

        private

        def option_keys
          [:type, :level]
        end

      end
    end
  end
end
