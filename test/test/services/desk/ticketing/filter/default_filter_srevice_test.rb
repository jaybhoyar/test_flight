# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  module Filter
    class DefaultFilterServiceTest < ActiveSupport::TestCase
      def setup
        @brad = create :user
        @organization = @brad.organization
        requester = create(:user, organization: @organization)
        @user_ethan = create(:user, organization: @organization)
        agent_smith = create(:user, organization: @organization)

        create(
          :ticket,
          organization: @organization,
          requester:,
          agent: @brad,
          subject: "Unable to generate invoice",
          priority: 2,
          status: "new",
          category: "None",
          number: 1,
          created_at: Date.current)
        create(
          :ticket,
          organization: @organization,
          requester:,
          agent: @brad,
          subject: "Unable to generate invoice",
          priority: 2,
          status: "closed",
          category: "None",
          number: 1,
          created_at: Date.current)
        create(
          :ticket,
          organization: @organization,
          requester:,
          agent: @brad,
          subject: "Unable to pay via stripe",
          category: "Questions",
          number: 2,
          priority: 0,
          status: "new",
          created_at: Date.current - 2.day)
        create(
          :ticket,
          organization: @organization,
          requester:,
          agent: @brad,
          subject: "Unable to pay, no payment button visible",
          category: "Incident",
          priority: 3,
          status: "on_hold",
          number: 3,
          created_at: Date.current - 1.day)
        create(
          :ticket,
          organization: @organization,
          requester:,
          agent: @user_ethan,
          subject: "Unable to login",
          category: "Problem",
          priority: 1,
          status: "open",
          number: 4,
          created_at: Date.current + 1.month)
        create(
          :ticket,
          organization: @organization,
          requester:,
          agent: @user_ethan,
          subject: "Unable to generate reset password mail",
          category: "Feature Request",
          priority: 0,
          status: "new",
          number: 5,
          created_at: Date.current - 1.day)
        create(
          :ticket,
          organization: @organization,
          requester: @brad,
          agent: agent_smith,
          subject: "Spinkart site is down",
          category: "Refund",
          priority: 2,
          number: 6,
          created_at: Date.current + 1.day).update!(status: "trash")
        create(
          :ticket,
          organization: @organization,
          requester: @brad,
          subject: "Spinkart site is down",
          category: "Refund",
          priority: 2,
          status: "on_hold",
          number: 6,
          created_at: Date.current + 1.day)
      end

      def test_status_filter
        default_filter_by = "open"
        open_tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 6, open_tickets.count
        open_tickets.each do |ticket|
          assert_includes ["new", "open", "on_hold", "waiting_on_customer", "resolved"], ticket.status
        end

        default_filter_by = "closed"
        closed_tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 1, closed_tickets.count
        closed_tickets.each do |ticket|
          assert_equal "closed", ticket.status
        end

        spam_ticket = open_tickets.first.update!(status: "spam")

        default_filter_by = "spam"
        all_spam_tickets = default_ticket_filter_service(@organization, default_filter_by)

        assert_equal 1, all_spam_tickets.count
        assert_equal 5, default_ticket_filter_service(@organization, "open").count
        all_spam_tickets.each do |ticket|
          assert_equal "spam", ticket.status
        end
      end

      def test_assigned_filter
        default_filter_by = "assigned"
        tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 5, tickets.count
        tickets.each do |ticket|
          assert_not_nil ticket.agent_id
        end
      end

      def test_unassigned_filter
        default_filter_by = "unassigned"
        tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 1, tickets.count
        tickets.each do |ticket|
          assert_nil ticket.agent_id
        end
      end

      def test_assigned_to_me_filter
        default_filter_by = "assigned_to_me"
        tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 3, tickets.count
        tickets.each do |ticket|
          assert_equal @brad.id, ticket.agent_id
        end
      end

      def test_all_filter
        default_filter_by = "all"
        tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 6, tickets.count
      end

      def test_unfiltered_filter
        default_filter_by = "unfiltered"
        tickets = default_ticket_filter_service(@organization, default_filter_by)
        assert_equal 6, tickets.count
      end

      def test_default_filter_by_customer_id
        customer_id = @brad.id
        default_filter_by = "unfiltered"
        tickets = default_ticket_filter_service(@organization, default_filter_by, customer_id)
        assert_equal 1, tickets.count
      end

      private

        def default_ticket_filter_service(organization, default_filter_by, customer_id = nil)
          Desk::Ticketing::Filter::DefaultFilterService.new(organization, default_filter_by, @brad, customer_id).process
        end
    end
  end
end
