# frozen_string_literal: true

class Desk::Automation::Rules::ExecutionService
  attr_reader :rule
  attr_accessor :errors, :status, :response

  def initialize(rule)
    @rule = rule
  end

  def process
    begin
      apply_rule
      set_success_response
    rescue ActiveRecord::RecordInvalid => invalid
      set_errors_response(invalid.record.errors.full_messages)
    end
  end

  private

    def apply_rule
      ActiveRecord::Base.transaction do
        @rule.matching_tickets.find_each(batch_size: 100) do |ticket|
          executed = true
          ticket_update_events = []
          @rule.actions.each do |action|
            response = action.execute!(ticket)
            if response
              ticket_update_events += action.event_names
            else
              executed = false
            end
          end

          if executed
            record_log_entry!(ticket)
            trigger_dependent_on_update_events(ticket, ticket_update_events)
          end
        end
      end
    end

    def record_log_entry!(ticket)
      Desk::Automation::ExecutionLogEntry.create!(rule:, ticket:)
    end

    def trigger_dependent_on_update_events(ticket, event_names)
      event_names.uniq.each do |event_name|
        ::Desk::ApplyTicketingAutomationRulesWorker.perform_async(ticket.id, event_name, "system")
      end
    end

    def set_errors_response(messages)
      @response = { errors: messages }
      @status = :unprocessable_entity
    end

    def set_success_response
      @response = { notice: "Rule has been successfully applied." }
      @status = :ok
    end
end
