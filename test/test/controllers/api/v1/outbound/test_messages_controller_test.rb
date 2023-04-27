# frozen_string_literal: true

require "test_helper"

class Api::V1::Outbound::TestMessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    @user = create :user, organization: @organization
    sign_in(@user)

    @outbound_test_message = create(:outbound_message, organization: @organization)
    host! test_domain(@organization.subdomain)
  end

  def test_send_test_email
    payload = {
      test_message: {
        title: "Updating Outbound Message",
        state: "Draft",
        email_subject: "Organization Invoice",
        email_content: "Please send the invoice on priority.",
        test_email_recepient: ["hello@example.com"]
      }
    }

    patch send_test_email_api_v1_outbound_test_message_url(@outbound_test_message.id, payload),
      headers: headers(@user)

    assert_response :ok

    assert_equal "Test message has been sent successfully.", json_body["notice"]
  end
end
