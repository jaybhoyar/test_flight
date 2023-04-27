# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class DeleteTicketsServiceTest < ActiveSupport::TestCase
    def setup
      @organization_role = create :organization_role_agent
      @user = create :user, role: @organization_role
      @organization = @user.organization
      @ticket = create :ticket, organization: @organization
    end

    def test_ticket_is_deleted
      @ticket.update!(status: "trash")

      service = Desk::Ticketing::DeleteTicketsService.new([@ticket])

      assert_difference "@organization.tickets.count", -1 do
        service.process
      end

      assert_equal "Ticket has been successfully deleted.", service.response
    end

    def test_that_a_task_ticket_is_deleted
      task = create :task, ticket: @ticket
      ticket_2 = create :ticket, organization: @organization, parent_task: task

      service = Desk::Ticketing::DeleteTicketsService.new([ticket_2])

      assert_difference "@organization.tickets.count", -1 do
        service.process
      end

      assert_equal "Ticket has been successfully deleted.", service.response
    end

    def test_that_subticket_is_deleted_along_with_the_ticket
      task = create :task, ticket: @ticket
      ticket_2 = create :ticket, organization: @organization, parent_task: task

      service = Desk::Ticketing::DeleteTicketsService.new([@ticket])

      assert_difference "@organization.tickets.count", -2 do
        service.process
      end

      assert_equal "Ticket has been successfully deleted.", service.response
    end
  end
end
