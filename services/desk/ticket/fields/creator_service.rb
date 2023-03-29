# frozen_string_literal: true

class Desk::Ticket::Fields::CreatorService
  attr_reader :ticket_field_options, :organization, :other_options

  def initialize(ticket_field_options, organization, options: {})
    @ticket_field_options = ticket_field_options
    @ticket_field_options[:organization_id] = organization && organization[:id]
    @other_options = options
  end

  def run
    Desk::Ticket::Field.transaction do
      ticket_field = Desk::Ticket::Field.create(ticket_field_options)
      update_ticket_statuses
      ticket_field
    end
  end

  def update_ticket_statuses
    return unless other_options.include?(:ticket_statuses) && ticket_field_options[:kind] == "system_status"

    other_options[:ticket_statuses].each do |status|
      status[:name] = status[:agent_label] if status[:name].blank?
      ticket_status = organization.ticket_statuses.find_or_create_by(name: status[:name])
      ticket_status.update(status)
    end
  end
end
