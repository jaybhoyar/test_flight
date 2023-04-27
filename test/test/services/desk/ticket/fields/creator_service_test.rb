# frozen_string_literal: true

require "test_helper"

class Desk::Ticket::Fields::CreatorServiceTest < ActiveSupport::TestCase
  setup do
    @organization = create :organization
  end

  test "should be able to create a new custom field with ticket options" do
    ticket_field_options = { agent_label: "Agent Label", is_required_for_agent_when_closing_ticket: true }

    assert_difference "Desk::Ticket::Field.count", 1 do
      Desk::Ticket::Fields::CreatorService.new(ticket_field_options, @organization).run
    end
  end

  test "should not create custom field without agent_label" do
    ticket_field_options = { is_required_for_agent_when_closing_ticket: true }

    assert_no_difference "Desk::Ticket::Field.count" do
      ticket_field = Desk::Ticket::Fields::CreatorService.new(ticket_field_options, @organization).run

      assert_not ticket_field.valid?
    end
  end

  test "should not create custom field without organization" do
    ticket_field_options = { agent_label: "Agent Label", is_required_for_agent_when_closing_ticket: true }

    assert_no_difference "Desk::Ticket::Field.count" do
      ticket_field = Desk::Ticket::Fields::CreatorService.new(ticket_field_options, nil).run

      assert_not ticket_field.valid?
    end
  end
end
