# frozen_string_literal: true

require "test_helper"

class Placeholders::TicketCarrierTest < ActiveSupport::TestCase
  def test_that_all_keys_are_present
    supported_variables = [
      "id", "number", "subject", "description", "source",
      "channel", "category", "priority", "status", "url",
      "customer_url", "link", "latest_comment", "created_at",
      "updated_at", "tags", "requester", "agent", "organization"
    ]

    organization = create :organization
    tag_1 = create :ticket_tag, organization: organization
    tag_2 = create :ticket_tag, organization: organization
    create :ticket_tag, organization: organization

    agent = create :user_with_agent_role, organization: organization
    customer = create :user, organization: organization, role: nil

    ticket = create :ticket, organization: organization, agent: agent, requester: customer
    ticket.update_tags([tag_1, tag_2])

    placeholder = Placeholders::TicketCarrier.new(ticket)
    assert_equal supported_variables, placeholder.build.keys
  end

  def test_that_kb_url_is_generated_for_customer
    organization = create :organization
    tag_1 = create :ticket_tag, organization: organization
    tag_2 = create :ticket_tag, organization: organization
    create :ticket_tag, organization: organization

    agent = create :user_with_agent_role, organization: organization
    customer = create :user, organization: organization, organization_role_id: nil

    ticket = create :ticket, organization: organization, agent: agent, requester: customer
    ticket.update_tags([tag_1, tag_2])

    customer_url = Placeholders::TicketCarrier.new(ticket, customer).build["url"]
    assert_includes customer_url, "/kb/tickets/#{ticket.number}"

    agent_url = Placeholders::TicketCarrier.new(ticket, agent).build["url"]
    assert_includes agent_url, "/tickets/#{ticket.id}"
  end
end
