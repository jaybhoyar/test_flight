# frozen_string_literal: true

class Desk::Organizations::Seeder::TicketFields
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def process!
    organization.ticket_fields.create! ticket_fields_options
    organization.ticket_statuses.create! statuses_options
  end

  private

    def ticket_fields_options
      [
        {
          kind: :system_subject,
          is_system: true,
          agent_label: "Subject",
          customer_label: "Subject",
          is_required_for_agent_when_submitting_form: true,
          is_shown_to_customer: true,
          is_editable_by_customer: true,
          is_required_for_customer_when_submitting_form: true,
          is_required_for_agent_when_closing_ticket: false
        },
        {
          kind: :system_category,
          is_system: true,
          agent_label: "Category",
          customer_label: "Category",
          is_required_for_agent_when_submitting_form: false,
          is_shown_to_customer: false,
          is_editable_by_customer: false,
          is_required_for_customer_when_submitting_form: false,
          is_required_for_agent_when_closing_ticket: false,
          ticket_field_options_attributes: [
            { name: "None" },
            { name: "Questions" },
            { name: "Incident" },
            { name: "Problem" },
            { name: "Feature Request" },
            { name: "Refund" }
          ]
        },
        {
          kind: :system_status,
          is_system: true,
          agent_label: "Status",
          customer_label: "Status",
          is_required_for_agent_when_submitting_form: false,
          is_shown_to_customer: false,
          is_editable_by_customer: false,
          is_required_for_customer_when_submitting_form: false,
          is_required_for_agent_when_closing_ticket: false
        },
        {
          kind: :system_priority,
          is_system: true,
          agent_label: "Priority",
          customer_label: "Priority",
          is_required_for_agent_when_submitting_form: true,
          is_shown_to_customer: true,
          is_editable_by_customer: true,
          is_required_for_customer_when_submitting_form: true,
          is_required_for_agent_when_closing_ticket: false
        },
        {
          kind: :system_group,
          is_system: true,
          agent_label: "Group",
          customer_label: "Group",
          is_required_for_agent_when_submitting_form: false,
          is_shown_to_customer: true,
          is_editable_by_customer: true,
          is_required_for_customer_when_submitting_form: true,
          is_required_for_agent_when_closing_ticket: false
        },
        {
          kind: :system_agent,
          is_system: true,
          agent_label: "Agent",
          customer_label: "Agent",
          is_required_for_agent_when_submitting_form: true,
          is_shown_to_customer: true,
          is_editable_by_customer: true,
          is_required_for_customer_when_submitting_form: true,
          is_required_for_agent_when_closing_ticket: false
        },
        {
          kind: :system_desc,
          is_system: true,
          agent_label: "Description",
          customer_label: "Description",
          is_required_for_agent_when_submitting_form: true,
          is_shown_to_customer: true,
          is_editable_by_customer: true,
          is_required_for_customer_when_submitting_form: true,
          is_required_for_agent_when_closing_ticket: false
        },
        {
          kind: :system_customer_email,
          is_system: true,
          agent_label: "Customer Email",
          customer_label: "Email",
          is_required_for_agent_when_submitting_form: true,
          is_shown_to_customer: true,
          is_editable_by_customer: true,
          is_required_for_customer_when_submitting_form: true,
          is_required_for_agent_when_closing_ticket: false
        }
      ]
    end

    def statuses_options
      [
        { name: "new", agent_label: "New", customer_label: "Open" },
        { name: "open", agent_label: "Open", customer_label: "Open" },
        { name: "on_hold", agent_label: "On Hold", customer_label: "Open" },
        {
          name: "waiting_on_customer", agent_label: "Waiting on Customer",
          customer_label: "Awaiting your reply"
        },
        { name: "resolved", agent_label: "Resolved", customer_label: "Resolved" },
        { name: "closed", agent_label: "Closed", customer_label: "Closed" },
        { name: "spam", agent_label: "Spam", customer_label: "Spam" },
        { name: "trash", agent_label: "Trash", customer_label: "Trash" }
      ]
    end
end
