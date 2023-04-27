# frozen_string_literal: true

require "test_helper"

class Desk::Ticket::Fields::UpdationServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
  end

  def test_updates_the_ticket_field
    ticket_field = create :ticket_field, organization: @organization

    Desk::Ticket::Fields::UpdationService.new(
      @organization,
      ticket_field,
      {
        ticket_field_params: {
          agent_label: "new agent label"
        }
      }
    ).process

    assert_equal "new agent label", ticket_field.reload.agent_label
  end

  def test_crud_on_status_fields
    ticket_field = create :ticket_field, :system_status, organization: @organization

    status_duplicate = create :desk_ticket_status,
      organization: @organization,
      name: "duplicate",
      agent_label: "Duplicate",
      customer_label: "Duplicate"

    create :desk_ticket_status,
      organization: @organization,
      name: "pending",
      agent_label: "Pending",
      customer_label: "Pending"

    payload = {
      ticket_field_params: {},
      ticket_statuses: [
        {
          agent_label: "Out of scope",
          customer_label: "Out of Scope"
        },
        {
          name: "duplicate",
          agent_label: "Duplicate",
          customer_label: "Marked as Duplicate"
        },
        {
          name: "pending",
          _destroy: true
        }
      ]
    }

    Desk::Ticket::Fields::UpdationService.new(@organization, ticket_field, payload).process

    assert_equal "Marked as Duplicate", status_duplicate.reload.customer_label
    assert_equal ["Out of scope", "duplicate"], @organization.ticket_statuses.pluck(:name).sort
  end
end
