# frozen_string_literal: true

class Desk::Ticketing::UpdateMultipleService
  attr_reader :response, :agent
  attr_accessor :tickets, :errors, :options

  def initialize(tickets, options)
    @tickets = tickets
    @options = options
    self.errors = []
  end

  def process
    set_agent if ticket_params[:agent_id]

    Ticket.transaction do
      tickets.each do |ticket|
        ticket_attributes = update_params(ticket)
        ticket.update(ticket_attributes)
        set_errors(ticket)
      end
    end

    create_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(record)
      if record.errors.any?
        errors << record.errors.full_messages.to_sentence
      end
    end

    def ticket_params
      options.permit(:status, :agent_id)
    end

    def create_service_response
      if errors.empty?
        change = options[:status] == "trash" ? "moved to trash" : options[:status] == "spam" ? "marked as spam" : "updated"
        @response = I18n.t("notice.common", resource: "Ticket", action: change, count: @tickets.size)
      end
    end

    def set_agent
      @agent = User.where(id: ticket_params[:agent_id]).preload(:groups).first
    end

    def update_params(ticket)
      return ticket_params unless ticket_params[:agent_id]

      group_id = agent&.group_ids&.include?(ticket.group_id) ? ticket.group_id : nil

      ticket_params.merge({ group_id: })
    end
end
