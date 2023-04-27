# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::ForwardsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @ticket = create(:ticket, organization: @organization, requester: @user)
    parent_comment = @ticket.comments.create!(
      info: "Issue will be resolved in latest release",
      author: @user,
      comment_type: "description")
    parent_comment.update_columns(latest: true)

    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_create_success
    payload = {
      forward_ticket: {
        forward_text: "Please take a look",
        forward_emails_attributes: [{ email: "christiano@ronaldo.com" }]
      }
    }

    assert_difference -> { @ticket.comments.count }, 1 do
      post api_v1_desk_ticket_forward_url(@ticket, payload),
        headers: headers(@user)
    end

    assert_response :ok
    assert json_body["comment"]

    expected = "Please take a look"
    assert_equal expected, json_body["comment"]["info"]
    assert_equal "forward", json_body["comment"]["comment_type"]
  end

  def test_create_failure
    payload = {
      forward_ticket: {
        forward_text: "",
        forward_emails_attributes: [{ email: "christiano@ronaldo.com" }]
      }
    }

    assert_no_difference -> { @ticket.comments.count } do
      post api_v1_desk_ticket_forward_url(@ticket, payload),
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Info can't be blank"], json_body["errors"]
  end

  def test_create_failure_with_no_forward_email
    payload = {
      forward_ticket: {
        forward_text: "Please take a look",
        forward_emails_attributes: [{ email: nil }]
      }
    }

    assert_no_difference -> { @ticket.comments.count } do
      post api_v1_desk_ticket_forward_url(@ticket, payload),
        headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_equal ["Forward emails email can't be blank", "Forward emails email is invalid"], json_body["errors"]
  end
end
