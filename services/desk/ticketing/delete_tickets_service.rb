# frozen_string_literal: true

module Desk::Ticketing
  class DeleteTicketsService
    attr_reader :response
    attr_accessor :errors, :tickets

    def initialize(tickets)
      @tickets = tickets
      @total_count = tickets.size
      self.errors = []
    end

    def process
      Ticket.transaction do
        tickets.each do |ticket|
          ticket.destroy
          set_errors(ticket)
        end
      end
      create_service_response
    end

    private

      def set_errors(ticket)
        if ticket.errors.any?
          errors.push(ticket.errors.full_messages.to_sentence)
        end
      end

      def create_service_response
        if @errors.empty?
          @response = I18n.t("notice.common", resource: "Ticket", action: "deleted", count: @total_count)
        end
      end
  end
end
