# frozen_string_literal: true

require "test_helper"

module Desk
  class Task::ListTest < ActiveSupport::TestCase
    def test_that_list_is_valid
      list = build :desk_task_list
      assert list.valid?
    end

    def test_that_list_is_invalid
      organization = create :organization
      create :desk_task_list, organization: organization, name: "Payment tasks"

      list = build :desk_task_list, organization: organization, name: "payment tasks"
      assert_not list.valid?

      list = build :desk_task_list, organization: organization, name: nil
      assert_not list.valid?
    end
  end
end
