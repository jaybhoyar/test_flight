# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class MultiValueOrSearchService < Base
      private

        def attribute_value
          filter_options[:value].split(",")
        end

        def processed_attributes_values
          rule == "empty" ? [nil] : attribute_value
        end
    end
  end
end
