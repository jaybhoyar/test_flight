# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::SpamsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @ticket = create(:ticket, organization: @organization)
    sign_in(@user)
    User.current = @user

    host! test_domain(@organization.subdomain)

    @desk_manage_permission = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, permissions: [@desk_manage_permission]
    @user.update(role:)
  end

  def test_restore_spam_tickets_success
    @ticket.update!(status: "spam")

    patch api_v1_desk_spam_url,
      params: spam_payload,
      headers: headers(@user)
    @ticket.reload
    assert_response :ok
    assert_equal "open", @ticket.status
  end

  def test_delete_spam_tickets_success
    @ticket.update!(status: "spam")

    assert_difference "::Ticket.count", -1 do
      delete api_v1_desk_spam_url,
        params: spam_payload,
        headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Ticket has been successfully deleted.", json_body["notice"]
  end

  private

    def spam_payload
      {
        ticket: {
          ids: [@ticket.id]
        }
      }
    end

    def ticket_payload_with_blocked_customer
      {
        ticket: {
          subject: "Vintage table lamp - Out of stock?",
          priority: "high",
          category: "None",
          customer_email: "matt@example.com",
          comments_attributes: {
            info: "I can’t find Vintage table lamp on site anymore. Is it out of stock or do you not sell those anymore?"
          }
        }
      }
    end
end
