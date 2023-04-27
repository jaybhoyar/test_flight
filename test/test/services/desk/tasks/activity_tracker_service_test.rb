
# frozen_string_literal: true

require "test_helper"

class Desk::Tasks::ActivityTrackerServiceTest < ActiveSupport::TestCase
  def setup
    organization = create(:organization)
    @agent_role = create(:organization_role_agent, organization:)
    @ticket = create :ticket,
      organization: organization,
      requester: create(:user, organization:, role: nil),
      agent: create(:user, organization:, role: @agent_role),
      number: 2,
      category: "Questions"
    agent_adam = create(:user, organization:, role: @agent_role)
    User.current = agent_adam
  end

  def test_logs_activity_for_tasks_creation
    assert_difference "Activity.count", 2 do

      task_attrs = { name: "Call customer" }
      task = @ticket.tasks.create(task_attrs)

      Desk::Tasks::ActivityTrackerService.new(task, "create").process

      assert_equal 2, @ticket.task_activities.count
    end
  end

  def test_logs_activity_for_tasks_updating
    assert_difference "Activity.count", 5 do

      task_attrs = { name: "Call customer" }
      task = @ticket.tasks.create(task_attrs)
      task.update!(name: "Call customer on skype.", status: "wont_do")

      Desk::Tasks::ActivityTrackerService.new(task, "update").process

      assert_equal 5, @ticket.task_activities.count
    end
  end

  def test_logs_activity_for_creating_sub_ticket
    task = create(:task, ticket: @ticket)
    converted_ticket = create :ticket,
      subject: task.name,
      requester: @ticket.requester,
      organization: @ticket.organization,
      channel: @ticket.channel,
      status: Ticket::INITIAL_STATUS,
      priority: @ticket.priority,
      category: @ticket.category,
      parent_task_id: task.id

    create :comment,
      ticket: converted_ticket,
      author: @ticket.requester,
      info: "Subticket of <a href='#{@ticket.url}'>##{@ticket.number}</a>."

    assert_difference "Activity.count", 1 do
      Desk::Tasks::ActivityTrackerService.new(task, "sub_ticket").process
    end
  end

  def test_logs_activity_for_tasks_deletion
    assert_difference "Activity.count", 3 do

      task_attrs = { name: "Call customer" }
      task = @ticket.tasks.create(task_attrs)
      task.destroy

      Desk::Tasks::ActivityTrackerService.new(task, "delete").process

      assert_equal 3, @ticket.task_activities.count
    end
  end
end
