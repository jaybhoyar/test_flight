# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::MergeTicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in @user

    create_tickets
    host! test_domain(@organization.subdomain)

    @desk_permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    @desk_permission_2 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    @desk_permission_3 = Permission.find_or_create_by(name: "desk.manage_own_tickets", category: "Desk")
    role = create :organization_role, permissions: [@desk_permission_1, @desk_permission_2, @desk_permission_3]
    @user.update(role:)
  end

  def test_that_tickets_can_be_merged
    params = {
      primary_ticket_number: @ticket_1.number,
      secondary_ticket_ids: [@ticket_2.id, @ticket_3.id]
    }
    get new_api_v1_desk_merge_ticket_path(params), headers: headers(@user)

    assert_response :ok
    assert_equal ["created_at", "id", "number", "requester", "subject"], json_body["ticket"].keys.sort
  end

  def test_that_source_ticket_cannot_be_merged_with_invalid_source
    ticket = create :ticket, status: "closed", organization: @organization

    params = {
      primary_ticket_number: "invalid-number",
      secondary_ticket_ids: [@ticket_2.id, @ticket_3.id]
    }
    get new_api_v1_desk_merge_ticket_path(params), headers: headers(@user)

    assert_response :not_found
    assert_equal "Could not find the ticket.", json_body["error"]
  end

  def test_that_tickets_are_merged
    params = {
      primary_ticket_number: @ticket_1.number,
      secondary_ticket_ids: [@ticket_2.id, @ticket_3.id],
      is_primary_comment_public: true,
      is_secondary_comment_public: true,
      primary_comment: "Requests ##{@ticket_2.number}, ##{@ticket_3.number}, #00000 will be merged into this request",
      secondary_comment: "This request will be closed and merged into ##{@ticket_1.number}"
    }
    assert_difference "Comment.count", 5 do
      post api_v1_desk_merge_tickets_path(params), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Tickets have been successfully merged.", json_body["notice"]

    assert_equal "open", @ticket_1.reload.status
    assert_equal "closed", @ticket_2.reload.status
    assert_equal "closed", @ticket_3.reload.status

    primary_comment = @ticket_1.comments.latest.first
    secondary_comment_1 = @ticket_2.comments.latest.first
    secondary_comment_2 = @ticket_3.comments.latest.first

    assert primary_comment.reply?
    assert secondary_comment_1.reply?
    assert secondary_comment_2.reply?

    assert primary_comment.info.to_s.include? "##{@ticket_2.number}"
    assert primary_comment.info.to_s.include? "##{@ticket_3.number}"

    assert secondary_comment_1.info.to_s.include? "##{@ticket_1.number}"
    assert secondary_comment_2.info.to_s.include? "##{@ticket_1.number}"
  end

  def test_that_tickets_are_merged_in_same_organization
    organization_2 = create :organization
    user = create(:user, organization: organization_2)
    ticket_11 = create :ticket, :with_desc, status: "open", organization: organization_2, requester: user
    ticket_11.update(number: @ticket_1.number)

    params = {
      primary_ticket_number: ticket_11.number,
      secondary_ticket_ids: [@ticket_2.id],
      is_primary_comment_public: true,
      is_secondary_comment_public: true,
      primary_comment: "Requests ##{@ticket_2.number} will be merged into this request",
      secondary_comment: "This request will be closed and merged into ##{@ticket_1.number}"
    }
    assert_difference "Comment.count", 3 do
      post api_v1_desk_merge_tickets_path(params), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "Ticket has been successfully merged.", json_body["notice"]

    assert_equal "open", @ticket_1.reload.status
    assert_equal "closed", @ticket_2.reload.status

    primary_comment = @ticket_1.comments.latest.first
    secondary_comment_1 = @ticket_2.comments.latest.first

    assert primary_comment.reply?
    assert secondary_comment_1.reply?

    assert primary_comment.info.to_s.include? "##{@ticket_2.number}"
    assert secondary_comment_1.info.to_s.include? "##{@ticket_1.number}"
  end

  def test_that_tickets_are_not_merged_from_other_organization
    organization_2 = create :organization
    user = create(:user, organization: organization_2)
    ticket_11 = create :ticket, :with_desc, status: "open", organization: organization_2, requester: user
    ticket_11.update(number: 99999999)

    params = {
      primary_ticket_number: 99999999,
      secondary_ticket_ids: [@ticket_2.id],
      is_primary_comment_public: true,
      is_secondary_comment_public: true,
      primary_comment: "Requests ##{@ticket_2.number} will be merged into this request",
      secondary_comment: "This request will be closed and merged into ##{@ticket_1.number}"
    }
    assert_no_difference "Comment.count" do
      post api_v1_desk_merge_tickets_path(params), headers: headers(@user)
    end

    assert_response :not_found
    assert_equal "Could not find the ticket.", json_body["error"]
  end

  # show
  def test_that_user_with_custom_role_and_permission_can_access_merge_ticket_details
    role = create :organization_role, :user_defined, permissions: [@desk_permission_1]
    @user.update(role:)
    get api_v1_desk_merge_ticket_url(@ticket_2.number), headers: headers(@user)

    assert_response :ok
  end

  def test_that_user_with_custom_role_without_permission_cannot_access_merge_ticket_details
    role = create :organization_role, :user_defined
    @user.update(role:)
    get api_v1_desk_merge_ticket_url(@ticket_2.number), headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_user_with_permissions_to_only_manage_own_tickets_cannot_access_other_tickets
    role = create :organization_role, :user_defined, permissions: [@desk_permission_3]
    @user.update(role:)
    get api_v1_desk_merge_ticket_url(@ticket_2.number), headers: headers(@user)

    assert_response :forbidden
  end

  def test_show_success
    get api_v1_desk_merge_ticket_url(@ticket_2.number), headers: headers(@user)

    assert_response :ok
  end

  def test_show_failure
    get api_v1_desk_merge_ticket_url(0), headers: headers(@user)
    assert_response :unprocessable_entity
  end

  private

    def create_tickets
      @ticket_1 = create :ticket, status: "open", organization: @organization,
        requester: create(:user, organization: @organization)
      @ticket_2 = create :ticket, status: "open", organization: @organization,
        requester: create(:user, organization: @organization)
      @ticket_3 = create :ticket, status: "open", organization: @organization,
        requester: create(:user, organization: @organization)
      create :comment, :description, ticket: @ticket_1, info: "Ticket 1 description"
      create :comment, :description, ticket: @ticket_2, info: "Ticket 2 description"
      create :comment, :description, ticket: @ticket_3, info: "Ticket 3 description"
    end
end
