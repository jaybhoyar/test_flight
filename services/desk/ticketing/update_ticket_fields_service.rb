# frozen_string_literal: true

module Desk::Ticketing
  class UpdateTicketFieldsService
    attr_accessor :organization, :ticket, :options

    def initialize(organization, ticket, options)
      @organization = organization
      @ticket = ticket
      @options = options
    end

    def process
      options.each do |ticket_field_params|
        update_ticket_field!(ticket_field_params)
      end
      update_multi_select_fields
    end

    private

      def update_ticket_field!(ticket_field_params)
        return store_multi_select_field_for_bulk_update(ticket_field_params) if multi_select_field?(ticket_field_params)

        ticket.update!(ticket_field_responses_attributes: [ticket_field_params])
      end

      def multi_select_field?(ticket_field_params)
        ticket_field_type(ticket_field_params[:ticket_field_id]) == "multi-select"
      end

      def store_multi_select_field_for_bulk_update(ticket_field_params)
        multi_select_fields << ticket_field_params
      end

      def update_multi_select_fields
        return if multi_select_fields.empty?

        ticket.update!(ticket_field_responses_attributes: multi_select_fields)
      end

      def ticket_field_type(ticket_field_id)
        if ticket_field_types.include?(ticket_field_id)
          ticket_field_types[ticket_field_id]
        else
          ticket_field_types[ticket_field_id] = organization.ticket_fields.find_by(id: ticket_field_id)&.kind
        end
      end

      def ticket_field_types
        @_ticket_field_types ||= {}
      end

      def multi_select_fields
        @_multi_select_fields ||= []
      end
  end
end
