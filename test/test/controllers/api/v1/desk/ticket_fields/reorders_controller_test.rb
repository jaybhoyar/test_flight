# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::TicketFields::ReoredersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_reorder_success
    field1 = create :ticket_field, organization: @organization
    field2 = create :ticket_field, :dropdown, organization: @organization

    payload = {
      reorder: {
        fields: [
          {
            id: field1.id,
            display_order: 1
          },
          {
            id: field2.id,
            display_order: 0
          }
        ]
      }
    }
    put api_v1_desk_ticket_fields_reorder_url(payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Fields have been re-ordered successfully.", json_body["notice"]
    assert_equal 1, field1.reload.display_order
  end
end
