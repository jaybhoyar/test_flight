# frozen_string_literal: true

require "test_helper"

class Desk::Ticket::Fields::SearchServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization

    @ticket_field_1 = create :ticket_field, organization: @organization
    @ticket_field_2 = create :ticket_field, :number, organization: @organization
  end

  def test_process_without_options_for_organization
    ticket_fields = Desk::Ticket::Fields::SearchService.new(@organization, nil).process

    assert_equal @organization.ticket_fields.count, ticket_fields.count
  end

  def test_process_for_organization_in_asc_order
    @ticket_field_1.update_attribute(:display_order, 99)

    options = { parent_field_type: "TicketFieldTicketOption" }
    ticket_fields = Desk::Ticket::Fields::SearchService.new(@organization, options).process

    assert_equal @ticket_field_1.id, ticket_fields.last.id
  end

  def test_process_for_tickets_ticket_fields
    options = { parent_field_type: "TicketFieldTicketOption" }
    ticket_fields = Desk::Ticket::Fields::SearchService.new(@organization, options).process

    assert_equal @ticket_field_1.id, ticket_fields[@ticket_field_1.display_order - 1]["id"]
    assert_equal @ticket_field_2.id, ticket_fields[@ticket_field_2.display_order - 1]["id"]
  end

  def test_search_success_with_term
    ticket_field = create(:ticket_field, agent_label: "Tracking Number", organization: @organization)
    options = { search_term: "ing" }
    ticket_fields = Desk::Ticket::Fields::SearchService.new(@organization, options).process

    assert_equal 1, ticket_fields.count
    assert_equal ticket_field.id, ticket_fields[0].id
  end
end
