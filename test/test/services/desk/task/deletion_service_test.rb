# frozen_string_literal: true

require "test_helper"
class Desk::Task::DeletionServiceTest < ActiveSupport::TestCase
  def test_that_multiple_task_list_are_deleted
    organization = create :organization
    list_1 = create :desk_task_list, :with_data, organization: organization, name: "Payment tasks"
    list_2 = create :desk_task_list, :with_data, organization: organization, name: "Payment tasks 2"
    list_3 = create :desk_task_list, :with_data, organization: organization, name: "Payment tasks 3"
    service = Desk::Task::DeletionService.new([list_1, list_2, list_3])
    assert_difference "Desk::Task::List.count", -3 do
      service.process
    end

    assert_equal :ok, service.status
    assert_equal "Lists have been successfully deleted.", service.response[:notice]
  end
end
