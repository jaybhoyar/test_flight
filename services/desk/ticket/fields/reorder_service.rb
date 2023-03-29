# frozen_string_literal: true

class Desk::Ticket::Fields::ReorderService
  attr_reader :organization, :options
  attr_accessor :errors, :status, :response

  def initialize(organization, options = {})
    @organization = organization
    @options = options
  end

  def process
    begin
      reorder_ticket_fields
      set_status_ok
      @response = json_response
    rescue ActiveRecord::RecordInvalid => invalid
      set_errors_and_status(invalid.record.errors.full_messages, status_unprocessable_entity)
    end
  end

  private

    def reorder_ticket_fields
      ActiveRecord::Base.transaction do
        options[:fields].each do |field_param|
          ticket_field = find_ticket_field(field_param[:id])
          ticket_field.update!(field_param)
        end
      end
    end

    def find_ticket_field(id)
      @organization.ticket_fields.find(id)
    end

    def set_errors_and_status(message, status)
      @errors = message
      @status = status
    end

    def status_unprocessable_entity
      :unprocessable_entity
    end

    def set_status_ok
      @status = :ok
    end

    def json_response
      { notice: "Fields have been re-ordered successfully." }
    end
end
