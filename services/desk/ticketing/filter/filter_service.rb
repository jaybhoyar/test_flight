# frozen_string_literal: true

module Desk::Ticketing
  module Filter
    class FilterService
      attr_reader :organization, :options, :tickets, :model_names

      def initialize(organization, options, tickets_to_filter)
        @options = options
        @organization = organization
        @tickets = tickets_to_filter
        @model_names = fetch_model_names
      end

      def process
        return tickets unless options && options[:filter_by]

        process_tickets_filters
        tickets
      end

      def search_service_class_name_for_filter(filter_name)
        case filter_name
        when "status", "priority", "category", "group_id", "agent_id", "requester_id", "channel"
          MultiValueOrSearchService
        when "taggings.tag_id"
          TagsFilterService
        when "created_at"
          DateFilterService
        when "keyword"
          KeywordSearchService
        end
      end

      private

        def process_tickets_filters
          options[:filter_by].each do |index, filter|
            filter_name = filter[:node]
            @tickets = search_service_class_name_for_filter(filter_name).new(
              @tickets, filter, organization.id,
              model_names).search
          end
        end

        def fetch_model_names
          options[:include_models].to_h.collect { |index, model| model[:value].to_sym }
        end
    end
  end
end
