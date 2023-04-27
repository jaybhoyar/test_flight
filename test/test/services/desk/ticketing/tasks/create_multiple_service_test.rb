# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class Tasks::CreateMultipleServiceTest < ActiveSupport::TestCase
    def setup
      @user = create :user
      @organization = @user.organization
    end

    def test_that_list_items_are_cloned
      ticket = create :ticket, organization: @organization

      payload = {
        tasks: [
          { name: "Task 1" },
          { name: "Task 2" },
          { name: "Task 3" }
        ]
      }
      assert_difference "ticket.tasks.count", 3 do
        Desk::Ticketing::Tasks::CreateMultipleService.new(ticket, payload).process
      end
    end
  end
end
