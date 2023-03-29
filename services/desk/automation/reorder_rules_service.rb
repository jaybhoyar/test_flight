# frozen_string_literal: true

class Desk::Automation::ReorderRulesService
  attr_reader :organization, :options
  attr_accessor :status, :response

  def initialize(organization, options = {})
    @organization = organization
    @options = options
  end

  def process
    begin
      reorder_rules
      set_status_ok
    rescue ActiveRecord::RecordInvalid => invalid
      set_error_response(invalid.record.errors.full_messages)
    end
  end

  private

    def reorder_rules
      ActiveRecord::Base.transaction do
        options[:rules].each do |rule_param|
          ticket_field = find_rule(rule_param[:id])
          ticket_field.update!(rule_param)
        end
      end
    end

    def find_rule(id)
      organization.rules.find(id)
    end

    def set_error_response(messages)
      @response = { errors: messages }
      @status = :unprocessable_entity
    end

    def set_status_ok
      @response = { notice: "Rules have been re-ordered successfully." }
      @status = :ok
    end
end
