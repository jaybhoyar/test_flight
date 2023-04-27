# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::CommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    @ticket = create(:ticket, organization: @organization, requester: @user)
    sign_in(@user)
    @comment = create(:comment, ticket: @ticket)

    host! test_domain(@organization.subdomain)

    @desk_permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    @desk_permission_2 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, permissions: [@desk_permission_1, @desk_permission_2]
    @user.update(role:)
  end

  def test_create_success
    payload = { comment: { info: "Urgent ticket" } }

    assert_difference "@ticket.comments.count", 1 do
      post api_v1_desk_ticket_comments_url(@ticket, payload),
        headers: headers(@user)
    end

    assert_response :ok
    assert json_body["comment"]
    assert_equal(
      [
        "attachments", "author", "channel_mode", "comment_type", "created_at",
        "forward_emails", "id", "info", "trix_info", "type"
      ],
      json_body["comment"].keys.sort
    )
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    payload = { comment: { info: "Urgent ticket" } }

    assert_no_difference "@ticket.comments.count" do
      post api_v1_desk_ticket_comments_url(@ticket, payload),
        headers: headers(@user)
    end

    assert_response :forbidden
  end

  def test_create_comment_with_attachments
    payload = { comment: { info: "Urgent ticket", attachments: [do_fake_direct_upload] } }
    assert_difference "Comment.joins(:attachments_attachments).count" do
      post api_v1_desk_ticket_comments_url(@ticket, payload),
        headers: headers(@user)
    end
    assert_response :ok
  end

  def test_create_failure
    invalid_payload = { comment: { info: "" } }

    assert_difference "@ticket.comments.count", 0 do
      post api_v1_desk_ticket_comments_url(@ticket, invalid_payload),
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Info can't be blank"], json_body["errors"]
  end

  def test_create_failure_when_author_id_is_invalid
    invalid_payload = { comment: { info: "Work in progress", author_id: 0 } }

    assert_difference "@ticket.comments.count", 0 do
      post api_v1_desk_ticket_comments_url(@ticket, invalid_payload),
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Author must exist"], json_body["errors"]
  end

  def test_comment_update_success
    payload = { comment: { info: "We will look into the issus soon!" } }

    patch api_v1_desk_ticket_comment_url(@ticket, @comment, payload),
      headers: headers(@user)

    assert_response :ok
    assert json_body["comment"]

    @comment.reload
    assert_equal "We will look into the issus soon!", @comment.info.to_plain_text
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    payload = { comment: { info: "We will look into the issus soon!" } }

    patch api_v1_desk_ticket_comment_url(@ticket, @comment, payload),
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_comment_update_failure
    invalid_payload = { comment: { info: "" } }

    patch api_v1_desk_ticket_comment_url(@ticket, @comment, invalid_payload),
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["Info can't be blank"], json_body["errors"]
  end

  def test_comment_destroy_success
    comment = create(:comment, ticket: @ticket)

    assert_difference "Comment.count", -1 do
      delete api_v1_desk_ticket_comment_url(@ticket, comment), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Reply has been successfully deleted.", json_body["notice"]
  end

  def test_that_destroy_doesnt_work_without_permissions
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)

    comment = create(:comment, ticket: @ticket)

    assert_no_difference "Comment.count" do
      delete api_v1_desk_ticket_comment_url(@ticket, comment), headers: headers(@user)
    end

    assert_response :forbidden
  end

  def test_index_success_with_filters
    comment_filter_params = { comment: { filter_by: { "0" => { node: "author_type", rule: "is", value: "Contact" } } } }
    get api_v1_desk_comments_url,
      params: comment_filter_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal 0, json_body["comments"].size

    comment_filter_params = {
      comment: {
        filter_by: {
          "0" => {
            node: "author_type", rule: "is",
            value: "User"
          }
        }
      }
    }
    get api_v1_desk_comments_url,
      params: comment_filter_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["comments"].size
  end

  def test_that_index_doesnt_work_without_permissions
    role = create :organization_role, :user_defined
    @user.update(role:)

    comment_filter_params = { comment: { filter_by: { "0" => { node: "author_type", rule: "is", value: "Contact" } } } }
    get api_v1_desk_comments_url,
      params: comment_filter_params,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_index_failure_without_filters
    get api_v1_desk_comments_url,
      headers: headers(@user)

    assert_response :bad_request
    assert_equal ["Insufficient parameters received"], json_body["errors"]
  end

  def test_that_automation_rule_is_applied_on_comment_creation
    Sidekiq::Testing.inline!

    @ticket.update(status: "resolved")
    refund_rule = create :automation_rule, :on_reply_added, organization: @organization
    group = create :automation_condition_group, rule: refund_rule
    create :desk_core_condition, conditionable: group, field: "status", verb: "is", value: "5"
    create :automation_action, rule: refund_rule, name: "change_ticket_status", status: "waiting_on_customer"

    assert_equal "resolved", @ticket.status

    payload = { comment: { info: "Urgent ticket" } }
    assert_difference ["Desk::Automation::ExecutionLogEntry.count", "@ticket.comments.count"] do
      post api_v1_desk_ticket_comments_url(@ticket, payload),
        headers: headers(@user)
    end

    assert_response :ok
    assert_equal "waiting_on_customer", @ticket.reload.status
  end
end

def do_fake_direct_upload
  blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("random text"), filename: "random.txt")
  blob.signed_id
end
