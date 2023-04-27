# frozen_string_literal: true

require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    organization = create(:organization)
    @agent_role = create :organization_role_agent, organization: organization
    @agent_adam = create(:user, organization:, role: @agent_role)
    @ticket = create(:ticket, organization:, agent: @agent_adam, number: 2, category: "Questions")

    User.current = @agent_adam
  end

  def test_logs_activity_for_tasks_creation
    assert_difference "Activity.count", 1 do
      action_key = "activity.ticket.tasks.create"
      task_attrs = { name: "Call customer" }

      task = @ticket.tasks.create(task_attrs)
      task_activity = Activity.find_by_key(action_key)

      assert_equal 2, @ticket.activities.count
      assert_equal @ticket, task_activity.trackable
      assert_equal @agent_adam.email, task_activity.owner.email
      assert_equal I18n.t(action_key, **task_attrs), task_activity.action
    end
  end

  def test_logs_activity_for_tasks_deletion
    assert_difference "Activity.count", 2 do
      action_key = "activity.ticket.tasks.delete"
      task_attrs = { name: "Call customer" }

      task = @ticket.tasks.create(task_attrs)
      task.destroy

      task_activity = Activity.find_by_key(action_key)

      assert_equal 3, @ticket.activities.count
      assert_equal @ticket, task_activity.trackable
      assert_equal @agent_adam.email, task_activity.owner.email
      assert_equal I18n.t(action_key, **task_attrs), task_activity.action
    end
  end

  def test_logs_activity_for_tasks_updating
    assert_difference "Activity.count", 3 do
      action_key = "activity.ticket.tasks.update"
      task_attrs = { name: "Call customer" }

      task = @ticket.tasks.create(task_attrs)
      task.update!(name: "Call customer on skype.", status: "wont_do")

      name_task_activity = Activity.find_by_key("#{action_key}.name")
      status_task_activity = Activity.find_by_key("#{action_key}.status")

      assert_equal 4, @ticket.activities.count

      assert_equal @ticket, name_task_activity.trackable
      assert_equal @ticket, status_task_activity.trackable

      assert_equal @agent_adam.email, name_task_activity.owner.email
      assert_equal @agent_adam.email, status_task_activity.owner.email

      assert name_task_activity.action.include?("on skype")
      assert status_task_activity.action.include?("Wont do")
    end
  end
end
