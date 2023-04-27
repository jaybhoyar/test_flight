# frozen_string_literal: true

require "test_helper"
class Desk::Ticket::Comment::EmailNotificationsServiceTest < ActiveSupport::TestCase
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

    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_that_emails_are_sent_to_all_followers_except_the_comment_author_and_customer_for_note
    ethan = create :user, :admin, organization: @organization, first_name: "Ethan"
    jason = create :user, :agent, organization: @organization, first_name: "Jason"

    follower_1 = create :desk_ticket_follower, ticket: @ticket, user: ethan
    follower_2 = create :desk_ticket_follower, ticket: @ticket, user: jason

    comment = create :comment, :note, ticket: @ticket, author: ethan

    assert_emails 2 do
      Desk::Ticket::Comment::EmailNotificationsService.new(@ticket, comment).process
    end
  end

  def test_that_it_works_when_comment_is_created_by_automations
    ethan = create :user, :admin, organization: @organization, first_name: "Ethan"
    jason = create :user, :agent, organization: @organization, first_name: "Jason"

    rule_1 = create :automation_rule_with_data, name: "Rule 1", organization: @organization

    follower_1 = create :desk_ticket_follower, ticket: @ticket, user: ethan
    follower_2 = create :desk_ticket_follower, ticket: @ticket, user: jason

    comment = create :comment, :note, ticket: @ticket, author: rule_1

    assert_emails 3 do
      Desk::Ticket::Comment::EmailNotificationsService.new(@ticket, comment).process
    end
  end
end
