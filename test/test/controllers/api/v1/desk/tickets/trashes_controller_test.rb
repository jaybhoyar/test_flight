# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::TrashesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @ticket = create(:ticket, organization: @organization)
    sign_in(@user)
    User.current = @user

    host! test_domain(@organization.subdomain)
  end

  def test_restore_trash_tickets_success
    @ticket.update!(status: "trash")

    patch api_v1_desk_trash_url,
      params: trash_payload,
      headers: headers(@user)
    @ticket.reload
    assert_response :ok
    assert_equal "open", @ticket.status
  end

  def test_delete_trash_tickets_success
    @ticket.update!(status: "trash")

    assert_difference "::Ticket.count", -1 do
      delete api_v1_desk_trash_url,
        params: trash_payload,
        headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Ticket has been successfully deleted.", json_body["notice"]
  end

  private

    def trash_payload
      {
        ticket: {
          ids: [@ticket.id]
        }
      }
    end
end
