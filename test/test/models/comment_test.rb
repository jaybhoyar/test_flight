# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @hunt = create :user, :admin, organization: @organization
    @ticket = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization),
      agent: @hunt,
      priority: 2,
      category: "None"
  end

  def test_that_comment_is_valid
    comment = build :comment, ticket: @ticket, author: @hunt
    assert comment.valid?
  end

  def test_authored_by_role
    comment_1 = create :comment, ticket: @ticket, author: @hunt
    comment_2 = create :comment, ticket: @ticket, author: @ticket.requester
    comment_3 = create :comment, ticket: @ticket, author: create(:automation_rule, organization: @organization)

    assert_equal "agent", comment_1.authored_by_role
    assert_equal "requester", comment_2.authored_by_role
    assert_equal "system", comment_3.authored_by_role
  end

  def test_that_comment_is_invalid
    comment = Comment.new
    assert_not comment.valid?
  end

  def test_that_information_is_not_redacted
    @organization.setting.update(automatic_redaction: false)

    cc_number = "5105 1051 0510 5100"
    comment = create :comment,
      ticket: @ticket,
      author: @hunt,
      info: "My card number is #{cc_number}, please fix the issue."

    assert_includes comment.info.to_plain_text, cc_number
  end

  def test_that_information_is_redacted_when_setting_is_enabled
    @organization.setting.update(automatic_redaction: true)

    cc_number = "5105 1051 0510 5100"
    comment = create :comment,
      ticket: @ticket,
      author: @hunt,
      info: "My card number is #{cc_number}, please fix the issue."

    assert_includes comment.info.to_plain_text, cc_number.slice(0...6)
    assert_not_includes comment.info.to_plain_text, cc_number
  end

  def test_that_phone_number_is_not_redacted
    @organization.setting.update(automatic_redaction: true)

    phone_number = Faker::PhoneNumber.phone_number
    cell_phone = Faker::PhoneNumber.cell_phone
    non_cc_number = 5850670427412957

    comment = create :comment,
      ticket: @ticket,
      author: @hunt,
      info: "My number is #{phone_number} and cell number is  #{cell_phone},  kindly fix issue number: #{non_cc_number}."

    assert_includes comment.info.to_plain_text, phone_number
    assert_includes comment.info.to_plain_text, cell_phone
    assert_includes comment.info.to_plain_text, non_cc_number.to_s
  end

  def test_that_activity_is_logged_on_create
    comment = nil
    assert_difference "Activity.count", 1 do
      comment = @ticket.comments.create!(info: "Issue will be resolved in latest release", author: @hunt)
    end

    first_activity = comment.activities.first

    assert_equal "activity.comment.ticket_response", first_activity.key
    assert_equal @hunt.name, first_activity.owner.name
    assert_equal I18n.t("activity.comment.ticket_response", name: @hunt.name), first_activity.action
  end

  def test_last_comment
    @ticket.comments.create!(info: "Issue will be resolved in latest release", author: @hunt)

    comment_2 = @ticket.comments.create!(info: "Thanks for the update", author: @hunt)
    assert_equal comment_2, @ticket.comments.last_comment
  end

  def test_that_latest_flag_is_updated_on_comments
    comment_1 = @ticket.comments.create!(info: "Issue will be resolved in latest release", author: @hunt)
    assert comment_1.latest

    comment_2 = @ticket.comments.create!(info: "Thanks for the update", author: @hunt)
    assert comment_2.latest
    assert_not comment_1.reload.latest
  end

  def test_do_not_allow_deleting_description
    comment = create :description_comment, ticket: @ticket
    assert_not comment.destroy
  end

  def test_can_delete_normal_comments
    comment = @ticket.comments.create!(info: "Thanks for the update", author: @ticket.requester)
    assert comment.destroy
  end

  def test_delete_ticket_with_description
    ticket = create :ticket, :with_desc, organization: @organization
    assert ticket.destroy
  end

  def test_that_followers_are_created_on_comment_create
    ticket = create :ticket, organization: @organization

    # No submitter, No Agent
    assert_difference "::Desk::Ticket::Follower.count", 1 do
      create :comment, ticket:
    end
  end

  def test_that_existing_requester_is_not_updated_on_commenting
    ticket = create :ticket, organization: @organization, requester: @hunt, agent: nil, submitter: nil
    follower = ticket.ticket_followers.where(user_id: @hunt.id).first

    assert follower.requester?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      create :comment, ticket:, author: @hunt
    end

    assert follower.reload.requester?
  end

  def test_that_existing_submitter_is_not_updated_on_commenting
    ticket = create :ticket, organization: @organization, agent: nil, submitter: @hunt
    follower = ticket.ticket_followers.where(user_id: @hunt.id).first

    assert follower.submitter?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      create :comment, ticket:, author: @hunt
    end

    assert follower.reload.submitter?
  end

  def test_that_existing_assigned_is_not_updated_on_commenting
    ticket = create :ticket, organization: @organization, agent: @hunt, submitter: nil
    follower = ticket.ticket_followers.where(user_id: @hunt.id).first

    assert follower.assigned?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      create :comment, ticket:, author: @hunt
    end

    assert follower.reload.assigned?
  end

  def test_that_existing_subscriber_is_updated_as_commented_on_commenting
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    follower = create :desk_ticket_follower, ticket: ticket, user: @hunt, kind: :subscriber

    assert follower.subscriber?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      create :comment, ticket:, author: @hunt
    end

    assert follower.reload.commented?
  end

  def test_that_existing_mentioned_is_updated_as_commented_on_commenting
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    follower = create :desk_ticket_follower, ticket: ticket, user: @hunt, kind: :mentioned

    assert follower.mentioned?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      create :comment, ticket:, author: @hunt
    end

    assert follower.reload.commented?
  end

  def test_that_existing_commented_is_not_duplicated_on_commenting
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    follower = create :desk_ticket_follower, ticket: ticket, user: @hunt, kind: :commented

    assert follower.commented?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      create :comment, ticket:, author: @hunt
    end

    assert follower.reload.commented?
  end
end
