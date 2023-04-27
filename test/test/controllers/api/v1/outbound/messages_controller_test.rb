# frozen_string_literal: true

require "test_helper"

class Api::V1::Outbound::MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)

    role = create :organization_role, organization: @organization
    @user.update(role:)
  end

  def test_index_success
    outbound_message1 = create(:outbound_message, organization: @organization, title: "Onboarding")
    outbound_message2 = create(:outbound_message, organization: @organization, title: "Getting Started")
    outbound_message3 = create(:outbound_message, organization: @organization, title: "Feedback")

    get api_v1_outbound_messages_url, headers: headers(@user)

    assert_response :ok
    assert_equal 3, json_body["outbound_messages"].size
    assert_equal outbound_message3.message_type, json_body["outbound_messages"][0]["message_type"]
    assert_equal outbound_message3.state, json_body["outbound_messages"][0]["state"]
    assert_equal \
      ["audience_type", "created_at", "id", "last_sent_at", "message_type", "recipients_count", "state", "title"].sort,
      json_body["outbound_messages"][0].keys.sort
    assert_equal @organization.outbound_messages.latest.first.title, outbound_message3.title
  end

  def test_create_success
    payload = {
      message: {
        state: "Sent",
        message_type: "ongoing",
        title: "Title of Outbound setting email",
        email_subject: "Setting up Outbound",
        email_content: "This is an Outbound message for testing"
      }
    }
    assert_difference "Outbound::Message.count", 1 do
      post api_v1_outbound_messages_url(payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Campaign has been successfully added.", json_body["notice"]
    assert_equal "Sent", Outbound::Message.last.state
    assert_equal "Title of Outbound setting email", Outbound::Message.last.title
    assert_equal "This is an Outbound message for testing", Outbound::Message.last.email_content.to_plain_text
    assert_equal "Setting up Outbound", Outbound::Message.last.email_subject
    assert_equal "ongoing", Outbound::Message.last.message_type
  end

  def test_show_success
    outbound_message = create(:outbound_message, organization: @organization)
    get api_v1_outbound_message_url(outbound_message.id), headers: headers(@user)

    assert_response :ok
    assert_equal \
      [
        "audience_type", "conditions", "created_at", "email_content", "email_subject", "id",
        "last_sent_at", "message_type", "recipients_count", "state", "title", "trix_email_content"
      ].sort,
      json_body["outbound_message"].keys.sort
  end

  def should_update_success
    outbound_message = create(:outbound_message, organization: @organization)
    payload = {
      message: {
        state: "Draft",
        message_type: "ongoing",
        title: "Title of Organization Invoice",
        email_subject: "Organization Invoice",
        email_content: "Please send the invoice on priority."
      }
    }

    patch api_v1_outbound_message_url(outbound_message.id, payload), headers: headers(@user)

    assert_response :ok

    outbound_message.reload
    assert_equal "Message has been successfully updated.", json_body["notice"]
    assert_equal "Title of Organization Invoice", outbound_message.title
    assert_equal "Organization Invoice", outbound_message.email_subject
    assert_equal "Please send the invoice on priority.", outbound_message.email_content.to_plain_text
  end

  def should_update_failure_with_errors
    outbound_message = create(:outbound_message, organization: @organization)
    payload = {
      message: {
        state: "Draft",
        message_type: "",
        email_subject: "Organization Invoice",
        email_content: "Please send the invoice on priority."
      }
    }

    patch api_v1_outbound_message_url(outbound_message.id, payload), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Message Type can't be blank"
    assert_includes json_body["errors"], "Title can't be blank"
  end

  def test_send_outbound_email
    outbound_message = create(:outbound_message, organization: @organization)

    outbound_delivery_window = create(:outbound_delivery_window, message_id: outbound_message.id)
    schedule = create(:delivery_schedule, delivery_window: outbound_delivery_window)

    payload = {
      message: {
        title: "Thanks for signing up on neetoDesk",
        state: "Draft",
        email_subject: "Welcome message!",
        email_content: "The unlocked benefits are as listed below."
      }
    }

    patch send_email_api_v1_outbound_message_url(outbound_message.id, payload), headers: headers(@user)

    assert_response :ok

    assert_equal "Message has been successfully updated.", json_body["notice"]
  end

  def test_delete_outbound_message
    outbound_message = create(:outbound_message, organization: @organization)

    delete api_v1_outbound_message_url(outbound_message.id), headers: headers(@user)

    assert_response :ok

    assert_equal "Outbound message has been successfully deleted.", json_body["notice"]
  end
end
