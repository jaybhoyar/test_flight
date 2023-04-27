# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::TasksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @ticket = create :ticket, organization: @user.organization

    @permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    @permission_2 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")
    role = create :organization_role, permissions: [@permission_1, @permission_2]
    @user.update(role:)

    host! test_domain(@user.organization.subdomain)
    sign_in(@user)
  end

  def test_index_success
    tasks = create_list(:task, 2, ticket: @ticket)

    get api_v1_desk_ticket_tasks_url(@ticket), headers: headers(@user)

    assert_response :ok
    assert_equal tasks.count, json_body["tasks"].count
  end

  def test_that_index_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    get api_v1_desk_ticket_tasks_url(@ticket), headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_success
    post api_v1_desk_ticket_tasks_url(@ticket),
      params: { task: { name: "Sample Task" } },
      headers: headers(@user)

    assert_response :created
    assert_equal "Task has been successfully added.", json_body["notice"]
    assert_equal 1, @ticket.tasks.count

    task = @ticket.tasks.first
    assert_equal "Sample Task", task.name
    assert_equal "incomplete", task.status
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@permission_1]
    @user.update(role:)

    post api_v1_desk_ticket_tasks_url(@ticket),
      params: { task: { name: "Sample Task" } },
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_destroy_success
    task = create(:task, ticket: @ticket)

    assert_difference -> { @ticket.tasks.where(id: task.id).count }, -1 do
      delete api_v1_desk_ticket_task_path(@ticket, task),
        headers: headers(@user)
    end

    assert_response :ok
  end

  def test_that_destroy_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@permission_1]
    @user.update(role:)

    task = create(:task, ticket: @ticket)

    assert_no_difference -> { @ticket.tasks.where(id: task.id).count }, -1 do
      delete api_v1_desk_ticket_task_path(@ticket, task),
        headers: headers(@user)
    end

    assert_response :forbidden
  end

  def test_update_success
    task = create(:task, ticket: @ticket)

    patch api_v1_desk_ticket_task_path(@ticket, task),
      params: { task: { name: "Updated name" } },
      headers: headers(@user)

    assert_response :ok
    assert_equal "Task has been successfully updated.", json_body["notice"]
    assert_equal "Updated name", task.reload.name
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@permission_1]
    @user.update(role:)

    task = create(:task, ticket: @ticket)

    patch api_v1_desk_ticket_task_path(@ticket, task),
      params: { task: { name: "Updated name" } },
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_create_multiple_success
    payload = {
      tasks: [
        { name: "Task 1" },
        { name: "Task 2" },
        { name: "Task 3" }
      ]
    }
    assert_difference "@ticket.tasks.count", 3 do
      post create_multiple_api_v1_desk_ticket_tasks_url(@ticket), params: payload, headers: headers(@user)
    end

    assert_response :ok
    assert_equal "3 tasks were has been successfully added.", json_body["notice"]
  end

  def test_that_create_multiple_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@permission_1]
    @user.update(role:)

    payload = {
      tasks: [
        { name: "Task 1" },
        { name: "Task 2" },
        { name: "Task 3" }
      ]
    }
    assert_no_difference "@ticket.tasks.count", 3 do
      post create_multiple_api_v1_desk_ticket_tasks_url(@ticket), params: payload, headers: headers(@user)
    end

    assert_response :forbidden
  end

  def test_update_multiple_success
    task_1 = create :task, ticket: @ticket, sequence: 1
    task_2 = create :task, ticket: @ticket, sequence: 2
    task_3 = create :task, ticket: @ticket, sequence: 3

    payload = {
      ticket: {
        id: @ticket.id,
        tasks_attributes: [
          { id: task_1.id, _destroy: true },
          { id: task_3.id, sequence: 1 },
          { id: task_2.id, sequence: 2 }
        ]
      }
    }
    assert_difference "@ticket.tasks.count", -1 do
      post update_multiple_api_v1_desk_ticket_tasks_url(@ticket), params: payload, headers: headers(@user)
    end

    assert_response :ok
  end

  def test_that_update_multiple_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@permission_1]
    @user.update(role:)

    task_1 = create :task, ticket: @ticket, sequence: 1
    task_2 = create :task, ticket: @ticket, sequence: 2
    task_3 = create :task, ticket: @ticket, sequence: 3

    payload = {
      ticket: {
        id: @ticket.id,
        tasks_attributes: [
          { id: task_1.id, _destroy: true },
          { id: task_3.id, sequence: 1 },
          { id: task_2.id, sequence: 2 }
        ]
      }
    }
    assert_no_difference "@ticket.tasks.count", -1 do
      post update_multiple_api_v1_desk_ticket_tasks_url(@ticket), params: payload, headers: headers(@user)
    end

    assert_response :forbidden
  end
end
