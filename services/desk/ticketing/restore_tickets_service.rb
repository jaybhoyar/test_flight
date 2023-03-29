# frozen_string_literal: true

module Desk::Ticketing
  class RestoreTicketsService
    attr_reader :response
    attr_accessor :errors, :tickets

    def initialize(tickets)
      @tickets = tickets
      self.errors = []
    end

    def process
      Ticket.transaction do
        tickets.each do |ticket|
          ticket.skip_status_validation = true
          ticket.update!(status: last_status_of_ticket(ticket))
          set_errors(ticket)
        end
      end
      create_service_response
    end

    private

      def last_status_of_ticket(ticket)
        activity = ticket.activities.where(key: "activity.ticket.update.status").order(created_at: :desc).first
        if activity && valid_ticket_status?(ticket, activity.old_value)
          activity.old_value
        else
          "open"
        end
      end

      def set_errors(ticket)
        if ticket.errors.any?
          errors.push(ticket.errors.full_messages.to_sentence)
        end
      end

      def create_service_response
        if @errors.empty?
          @response = I18n.t("notice.common", resource: "Ticket", action: "restored", count: tickets.size)
        end
      end

      def valid_ticket_status?(ticket, status)
        ticket.organization.ticket_statuses.where(name: status).exists?
      end
  end
end
