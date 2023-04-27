# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class Tasks::ListCloneServiceTest < ActiveSupport::TestCase
    def setup
      @user = create :user
      @organization = @user.organization
    end

    def test_that_list_items_are_cloned
      ticket = create :ticket, organization: @organization
      tasks_list = create :desk_task_list, :with_data, organization: @organization

      assert_difference "ticket.tasks.count", 5 do
        Desk::Ticketing::Tasks::ListCloneService.new(ticket, tasks_list).process
      end
    end
  end
end
