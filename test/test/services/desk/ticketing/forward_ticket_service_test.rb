# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class ForwardTicketServiceTest < ActiveSupport::TestCase
    setup do
      @user = create :user
      organization = @user.organization
      @ticket = create(
        :ticket, organization:,
        requester: create(:user), agent: @user, priority: 2, category: "None")
      parent_comment = @ticket.comments.create!(
        info: "Issue will be resolved in latest release",
        author: @user,
        comment_type: "description")

      parent_comment.update_columns(latest: true)
      @forward_text = "Can you please take at look?"
      @forward_emails = [{ email: "john@example.com" }, { email: "cristiano@ronaldo.com" }]
    end

    def test_comment_create_success
      assert_difference -> { Comment.count }, 1 do
        Desk::Ticketing::ForwardTicketService.new(
          @ticket, @forward_text, @forward_emails, [],
          @user).process
      end
    end

    def test_comment_create_doesnt_fail_with_a_required_ticket_fields
      @ticket.update(status: :closed)

      create :ticket_field,
        agent_label: "Customer Last Name",
        is_required_for_agent_when_closing_ticket: true,
        organization: @user.organization

      assert_difference -> { Comment.count }, 1 do
        Desk::Ticketing::ForwardTicketService.new(
          @ticket, @forward_text, @forward_emails, [],
          @user).process
      end
    end

    def test_forward_comment_create_success
      forward_comment = Desk::Ticketing::ForwardTicketService.new(
        @ticket, @forward_text, @forward_emails, [],
        @user).process

      assert_equal @forward_text, forward_comment.info.to_plain_text
      assert_equal "forward", forward_comment.comment_type
      assert forward_comment.latest?
    end
  end
end
