# frozen_string_literal: true

require "test_helper"

class Api::V1::Outbound::MessageEventsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_index_success
    outbound_message_event = create(:message_event)

    get api_v1_outbound_message_events_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["outbound_message_events"].size

    assert_equal outbound_message_event.user_id,
      json_body["outbound_message_events"][0]["user_id"]
    assert_equal outbound_message_event.email_contact_detail_id,
      json_body["outbound_message_events"][0]["email_contact_detail_id"]
    assert_equal outbound_message_event.message_id, json_body["outbound_message_events"][0]["message_id"]
  end
end
