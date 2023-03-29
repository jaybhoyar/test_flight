# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class Base
      attr_reader :rule, :tickets, :column, :filter_options, :model_names

      def initialize(tickets, filter_options, _organization_id, model_names = [])
        @rule = filter_options[:rule].underscore
        @column = filter_options[:node].underscore
        @filter_options = filter_options
        @tickets = tickets
        @model_names = model_names
      end

      def search
        if column === "taggings.tag_id"
          model_names = "taggings"
        end
        tickets.includes(model_names).where("#{column}": processed_attributes_values)
      end

      private

        def processed_attributes_values
          raise "Implement in child class"
        end
    end
  end
end
