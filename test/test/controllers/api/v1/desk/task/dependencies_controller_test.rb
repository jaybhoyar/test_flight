# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Task::DependenciesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_task_list_returns_dependencies
    task_list = create :desk_task_list, :with_data, organization: @organization
    rule = create :automation_rule, organization: @organization
    group_1 = create :automation_condition_group, rule: rule
    create :automation_condition, conditionable: group_1, field: "subject", verb: "is", value: "xxx"
    action = create :automation_action, rule: rule, actionable: task_list

    get api_v1_desk_task_list_dependencies_url(task_list), headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["dependencies"].count

    dependency_ids = json_body["dependencies"].map { |dependency| dependency["id"] }
    assert dependency_ids.include?(rule.id)
  end

  def test_task_list_returns_no_dependencies
    task_list = create :desk_task_list, :with_data, organization: @organization

    get api_v1_desk_task_list_dependencies_url(task_list), headers: headers(@user)

    assert_response :ok
    assert_equal 0, json_body["dependencies"].count
  end
end
