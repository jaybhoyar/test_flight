# frozen_string_literal: true

require "test_helper"

class Api::V1::Public::TicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization

    host! test_domain(@organization.subdomain)
  end

  def test_create_ticket_success
    assert_difference "@organization.tickets.count", 1 do
      post api_v1_public_tickets_url,
        params: {
          name: "Matt Smith",
          email: "matt@example.com",
          subject: "Need help!",
          description: "Need help with widget setup!",
          channel: "chat"
        },
        headers: {
          "X-Neeto-Api-Key": @organization.api_key
        }
    end

    assert_response :ok
    assert_equal "Ticket has been successfully submitted.", json_body["notice"]

    ticket = @organization.tickets.find_by(subject: "Need help!")
    assert ticket.chat?
  end

  def test_that_create_fails_without_api_key
    assert_no_difference "@organization.tickets.count", 1 do
      post api_v1_public_tickets_url,
        params: {
          name: "Matt Smith",
          email: "matt@example.com",
          subject: "Need help!",
          description: "Need help with widget setup!",
          channel: "chat"
        }
    end

    assert_response :unauthorized
    assert_equal "Could not authenticate, please login to continue!", json_body["error"]
  end

  def test_that_create_fails_with_invalid_api_key
    assert_no_difference "@organization.tickets.count", 1 do
      post api_v1_public_tickets_url,
        params: {
          name: "Matt Smith",
          email: "matt@example.com",
          subject: "Need help!",
          description: "Need help with widget setup!",
          channel: "chat"
        },
        headers: {
          "X-Neeto-Api-Key": "invalid-api-key"
        }
    end

    assert_response :unauthorized
    assert_equal "Could not authenticate, please login to continue!", json_body["error"]
  end

  def test_create_ticket_success_without_channel
    assert_difference "@organization.tickets.count", 1 do
      post api_v1_public_tickets_url,
        params: {
          name: "Matt Smith",
          email: "matt@example.com",
          subject: "Need help!",
          description: "Need help with widget setup!"
        },
        headers: {
          "X-Neeto-Api-Key": @organization.api_key
        }
    end

    assert_response :ok
    assert_equal "Ticket has been successfully submitted.", json_body["notice"]

    ticket = @organization.tickets.find_by(subject: "Need help!")
    assert ticket.email?
  end
end
