# frozen_string_literal: true

require "test_helper"

class Api::V1::Outbound::OngoingControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)

    role = create :organization_role, organization: @organization
    @user.update(role:)
  end

  def test_index_returns_ongoing_messages
    message_options = {
      message_type: Outbound::Message::message_types[:ongoing],
      organization: @organization
    }

    outbound_message1 = create(:outbound_message, message_options)
    outbound_message2 = create(:outbound_message, message_options)

    message_options[:message_type] = Outbound::Message::message_types[:broadcast]
    create(:outbound_message, message_options)

    get api_v1_outbound_ongoing_index_url, headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["ongoing_messages"].size

    first_message = json_body["ongoing_messages"][0]
    assert_equal outbound_message1.message_type, first_message["message_type"]
    assert_equal outbound_message1.state, first_message["state"]
    assert_equal ["created_at", "id", "last_sent_at", "message_type", "recipients_count", "state", "title"].sort,
      first_message.keys.sort

    response_message_types = json_body["ongoing_messages"].map { |ongoing_message| ongoing_message["message_type"] }
    assert_not response_message_types.include?("broadcast")
  end

  def test_index_with_search
    outbound_message1 = create(
      :outbound_message, {
        message_type: Outbound::Message::message_types[:ongoing],
        organization: @organization, title: "Test message task 1"
      })
    outbound_message2 = create(
      :outbound_message, {
        message_type: Outbound::Message::message_types[:ongoing],
        organization: @organization, title: "Test message task 2"
      })
    outbound_message3 = create(
      :outbound_message, {
        message_type: Outbound::Message::message_types[:ongoing],
        organization: @organization, title: "Test message task 3"
      })

    params = { search_string: "task 2" }

    get api_v1_outbound_ongoing_index_url(params), headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["ongoing_messages"].size
  end

  def test_delete_returns_remaining_ongoing_messages
    message_options = {
      message_type: Outbound::Message::message_types[:ongoing],
      organization: @organization
    }

    outbound_message1 = create(:outbound_message, message_options)
    outbound_message2 = create(:outbound_message, message_options)
    outbound_message3 = create(:outbound_message, message_options)

    payload = {
      message_ids: [outbound_message2.id],
      page: 1
    }

    delete destroy_multiple_api_v1_outbound_ongoing_index_url(payload), headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["ongoing_messages"].size

    first_message = json_body["ongoing_messages"][0]
    assert_equal outbound_message1.message_type, first_message["message_type"]
    assert_equal outbound_message1.state, first_message["state"]
    assert_equal ["created_at", "id", "last_sent_at", "message_type", "recipients_count", "state", "title"].sort,
      first_message.keys.sort

    response_message_types = json_body["ongoing_messages"].map { |ongoing_message| ongoing_message["message_type"] }
    response_message_ids = json_body["ongoing_messages"].map { |ongoing_message| ongoing_message["id"] }

    assert_not response_message_types.include?("broadcast")
    assert_not response_message_ids.include?(outbound_message2.id)
  end
end
