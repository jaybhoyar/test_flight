# frozen_string_literal: true

class Desk::Ticket::Fields::UpdationService
  attr_reader :organization, :ticket_field, :options
  attr_accessor :errors

  def initialize(organization, ticket_field, options)
    @organization = organization
    @ticket_field = ticket_field
    @options = options
    @errors = []
  end

  def process
    Desk::Ticket::Field.transaction do
      if ticket_field.update(options[:ticket_field_params])
        update_ticket_statuses
      else
        errors.concat ticket_field.errors.full_messages
      end

      raise ActiveRecord::Rollback unless valid?
    end
    ticket_field
  end

  def valid?
    errors.blank?
  end

  private

    def update_ticket_statuses
      return unless options.include?(:ticket_statuses) && ticket_field.kind == "system_status"

      options[:ticket_statuses].each do |status|
        status[:name] = status[:agent_label] if status[:name].blank?
        if status[:_destroy]
          organization.ticket_statuses.find_by(name: status[:name])&.destroy
        else
          ticket_status = organization.ticket_statuses.find_or_create_by(name: status[:name])
          unless ticket_status.update(status)
            errors.concat ticket_status.errors.full_messages
          end
        end
      end
    end
end
