# frozen_string_literal: true

require "test_helper"
class Desk::Ticket::Comment::CreateServiceTest < ActiveSupport::TestCase
  def setup
    @user = create :user, :agent
    @organization = @user.organization

    User.current = @user

    @ticket = create :ticket, :with_desc,
      organization: @organization,
      requester: create(:user),
      agent: @user,
      priority: 2,
      category: "None"

    create(:email_configuration, organization: @organization)
  end

  def test_resolved_ticket_status_do_not_change_after_adding_comment_by_agent
    @ticket.update(status: Ticket::DEFAULT_STATUSES[:resolved])

    comment = Desk::Ticket::Comment::CreateService.new(@ticket, comment_params(@ticket.agent_id)).process
    assert_equal @ticket.status, "resolved"
  end

  def test_ticket_status_does_not_change_if_comment_added_by_unassigned_agent
    brad = create(:user)

    assert_equal @ticket.status, "open"
    comment = Desk::Ticket::Comment::CreateService.new(@ticket, comment_params(brad.id)).process
    assert_equal @ticket.status, "open"
  end

  def test_creates_comment
    assert_difference "Comment.count", 1 do
      Desk::Ticket::Comment::CreateService.new(@ticket, comment_params(@ticket.agent_id)).process
    end
  end

  def test_creates_comment_of_note_type_and_does_not_send_email
    payload = comment_params(@ticket.agent_id).merge(comment_type: :note)

    assert_no_emails do
      assert_difference "Comment.count", 1 do
        Desk::Ticket::Comment::CreateService.new(@ticket, payload).process
      end
    end

    assert_equal "note", @ticket.reload.latest_comment.comment_type
  end

  def test_comment_creation_fails_for_invalid_params
    invalid_comment_params = { info: "Could you specific the invoice number that has issue?" }

    comment = Desk::Ticket::Comment::CreateService.new(@ticket, invalid_comment_params).process

    assert_equal @ticket.status, "open"
    assert_equal ["Author must exist"], comment.errors.full_messages
  end

  def test_that_automation_rule_is_applied_on_comment_creation
    Sidekiq::Testing.inline!

    @ticket.update(status: "resolved")

    refund_rule = create :automation_rule, :on_reply_added, organization: @organization
    group = create :automation_condition_group, rule: refund_rule
    create :desk_core_condition, conditionable: group, field: "status", verb: "is", value: "5"
    create :automation_action, rule: refund_rule, name: "change_ticket_status", status: "waiting_on_customer"

    assert @ticket.reload.status == "resolved"

    assert_difference ["Desk::Automation::ExecutionLogEntry.count", "Comment.count"] do
      Desk::Ticket::Comment::CreateService.new(@ticket, comment_params(@ticket.agent_id)).process
    end
    assert @ticket.reload.status == "waiting_on_customer"
  end

  def test_that_automation_rules_are_not_applied_when_skip_param_is_passed
    Sidekiq::Testing.inline!

    @ticket.update(status: "resolved")
    refund_rule = create :automation_rule, :on_reply_added, organization: @organization
    group = create :automation_condition_group, rule: refund_rule
    create :desk_core_condition, conditionable: group, field: "status", verb: "is", value: "5"
    create :automation_action, rule: refund_rule, name: "change_ticket_status", status: "waiting_on_customer"

    assert_no_difference ["Desk::Automation::ExecutionLogEntry.count"] do
      Desk::Ticket::Comment::CreateService.new(@ticket, comment_params(@ticket.agent_id), true).process
    end
  end

  def test_on_create_emails_are_sent_to_all_followers_except_the_author_of_the_comment
    ethan = create :user, organization: @organization, first_name: "Ethan"
    jason = create :user, organization: @organization, first_name: "Jason"

    follower_1 = create :desk_ticket_follower, ticket: @ticket, user: ethan
    follower_2 = create :desk_ticket_follower, ticket: @ticket, user: jason

    stub_request(:any, /fonts.googleapis.com/)

    assert_emails 3 do
      assert_difference "Comment.count", 1 do
        Desk::Ticket::Comment::CreateService.new(@ticket, comment_params(@ticket.agent_id)).process
      end
    end
  end

  def test_on_note_create_emails_are_sent_to_all_followers_except_the_comment_author_and_customer
    ethan = create :user, :admin, organization: @organization, first_name: "Ethan"
    jason = create :user, :agent, organization: @organization, first_name: "Jason"

    follower_1 = create :desk_ticket_follower, ticket: @ticket, user: ethan
    follower_2 = create :desk_ticket_follower, ticket: @ticket, user: jason

    stub_request(:any, /fonts.googleapis.com/)

    assert_emails 2 do
      assert_difference "Comment.count", 1 do
        Desk::Ticket::Comment::CreateService.new(
          @ticket,
          comment_params(@ticket.agent_id).merge(comment_type: :note)
        ).process
      end
    end
  end

  private

    def comment_params(author_id)
      {
        info: "Could you specific the invoice number that has issue?",
        author_id:,
        author_type: "User"
      }
    end

    def setup_customer_satisfaction_survey_factories(email_state)
      @ticket = create :ticket_with_email_config,
        organization: @organization,
        requester: create(:user)

      survey = create(:default_survey, organization: @organization, email_state:)
      survey_question = create(:default_question, survey:)
      create(:default_question_scale_choice_1, question: survey_question)
      create(:comment, ticket: @ticket, author: @ticket.requester)
    end
end
