# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class SortServiceTest < ActiveSupport::TestCase
    def setup
      @organization = create(:organization)
      @payment_issue_ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 3,
        status: "on_hold",
        number: 3,
        category: "Incident",
        created_at: Date.current - 1.day
    end

    # TextSearchService cases
    def test_sorted_tickets
      options = { sort_by: { column: "created_at", direction: "desc" } }
      sorted_tickets = Desk::Ticketing::SortService.new(@organization.tickets, options).sorted_tickets
      assert_equal sorted_tickets.first.number, @payment_issue_ticket.number

      options = { sort_by: { column: "status", direction: "desc" } }
      sorted_tickets = Desk::Ticketing::SortService.new(@organization.tickets, options).sorted_tickets
      assert_equal sorted_tickets.first.number, @payment_issue_ticket.number
    end

    def test_sorted_tickets_default_sorting
      hunt = create(:user, organization: @organization)
      new_comment = @payment_issue_ticket.comments.create!(
        info: "Issue will be resolved in latest release",
        author: hunt
      )
      sorted_tickets = Desk::Ticketing::SortService.new(@organization.tickets, {}).sorted_tickets
      assert_equal sorted_tickets.last.number, @payment_issue_ticket.number
    end
  end
end
