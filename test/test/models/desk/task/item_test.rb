# frozen_string_literal: true

require "test_helper"

module Desk
  class Task::ItemTest < ActiveSupport::TestCase
    def test_that_item_is_valid
      item = build :desk_task_item
      assert item.valid?
    end

    def test_that_item_is_valid
      list = create :desk_task_list
      create :desk_task_item, list: list, name: "Task 1"
      item = build :desk_task_item, list: list, name: "task 1"
      assert_not item.valid?
    end
  end
end
