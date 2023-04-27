# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::RulesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_automation_rules", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_that_rule_is_created
    ticket_tag = create :ticket_tag

    payload = {
      rule: {
        name: "Assign billing tag",
        channel: "ui",
        description: "assign #billing when subject contains refund",
        events_attributes: [
          {
            name: "created"
          }
        ],
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: "Refund"
              },
              {
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: "Refund"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "set_tags",
            tag_ids: [ticket_tag.id]
          }
        ]
      }
    }
    assert_difference ["Desk::Automation::Rule.count", "Desk::Automation::Action.count"] do
      assert_difference "Desk::Automation::Condition.count", 2 do
        post api_v1_desk_automation_rules_url(payload), headers: headers(@user)
      end
    end
    assert_response :ok
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    post api_v1_desk_automation_rules_url({ name: "test" }), headers: headers(@user)
    assert_response :forbidden
  end

  def test_that_rule_is_not_created_with_invalid_data
    payload = {
      rule: {
        name: nil,
        execute: nil,
        description: nil,
        condition_groups_attributes: [
          {
            join_type: nil,
            conditions_join_type: nil,
            conditions_attributes: [
              {
                join_type: nil,
                field: nil,
                verb: nil,
                value: nil
              }
            ]
          }
        ]
      }
    }
    assert_no_difference "Desk::Automation::Rule.count" do
      post api_v1_desk_automation_rules_url(payload), headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name is required"
  end

  def test_that_rules_list_is_returned
    create :automation_rule_with_data, name: "Billing", organization: @organization
    create :automation_rule_with_data, name: "Priority", organization: @organization

    get api_v1_desk_automation_rules_url, headers: headers(@user)
    assert_response :ok
    assert_equal 2, json_body["rules"].count
  end

  def test_that_rule_is_updated
    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    ticket_tag = create :ticket_tag

    group = automation_rule.condition_groups.first
    payload = {
      rule: {
        name: "Assign billing tag",
        description: "assign #billing when subject contains refund",
        events_attributes: [
          {
            name: "updated"
          }
        ],
        condition_groups_attributes: [
          {
            id: group.id,
            join_type: group.join_type,
            conditions_join_type: group.conditions_join_type,
            conditions_attributes: [
              {
                id: group.conditions.first.id,
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: "refunding"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            id: automation_rule.actions.first.id,
            name: "set_tags",
            tag_ids: [ticket_tag.id]
          }
        ]
      }
    }
    assert_no_difference ["Desk::Automation::Rule.count", "Desk::Automation::Condition.count",
"Desk::Automation::Action.count"] do
      put api_v1_desk_automation_rule_url(automation_rule, payload), headers: headers(@user)
    end
    assert_response :ok
    automation_rule.reload
    assert_equal "Assign billing tag", automation_rule.name
    assert_equal "refunding", group.reload.conditions.first.value
    assert_equal "set_tags", automation_rule.actions.first.name
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    put api_v1_desk_automation_rule_url(automation_rule), headers: headers(@user)
    assert_response :forbidden
  end

  def test_that_rules_list_is_paginated
    15.times { |i| create :automation_rule_with_data, name: " #{"test" + i.to_s} ", organization: @organization }

    rule_filter_params = { page_index: 1, limit: 2 }

    get api_v1_desk_automation_rules_url,
      params: rule_filter_params,
      headers: headers(@user)

    assert_response :ok

    assert_equal 2, json_body["rules"].size
    assert_equal 15, json_body["total_count"]
  end

  def test_that_conditions_and_actions_are_created_while_updating_the_rule
    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    ticket_tag = create :ticket_tag

    group = automation_rule.condition_groups.first
    payload = {
      rule: {
        name: "Assign billing tag",
        description: "assign #billing when subject contains refund",
        events_attributes: [
          {
            name: "updated"
          }
        ],
        condition_groups_attributes: [
          {
            id: group.id,
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                id: group.conditions.first.id,
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: "refunding"
              }, {
                join_type: "or_operator",
                field: "subject",
                verb: "contains",
                value: "refunds"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            id: automation_rule.actions.first.id,
            name: "set_tags",
            tag_ids: [ticket_tag.id]
          }, {
            name: "set_tags",
            tag_ids: [ticket_tag.id]
          }
        ]
      }
    }
    assert_no_difference "Desk::Automation::Rule.count" do
      assert_difference ["Desk::Automation::Condition.count", "Desk::Automation::Action.count"] do
        put api_v1_desk_automation_rule_url(automation_rule, payload), headers: headers(@user)
      end
    end
    assert_response :ok
  end

  def test_that_conditions_and_actions_are_deleted_while_updating_the_rule
    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization

    group = automation_rule.condition_groups.first
    payload = {
      rule: {
        name: "Assign billing tag",
        description: "assign #billing when subject contains refund",
        events_attributes: [
          {
            name: "updated"
          }
        ],
        condition_groups_attributes: [
          {
            id: group.id,
            conditions_attributes: [
              {
                id: group.conditions.first.id,
                _destroy: true
              }
            ]
          }
        ],
        actions_attributes: [
          {
            id: automation_rule.actions.first.id,
            _destroy: true
          }
        ]
      }
    }
    assert_no_difference "Desk::Automation::Rule.count" do
      assert_difference ["Desk::Automation::Condition.count", "Desk::Automation::Action.count"], -1 do
        put api_v1_desk_automation_rule_url(automation_rule, payload), headers: headers(@user)
      end
    end
    assert_response :ok
  end

  def test_that_rule_is_not_updated_with_invalid_data
    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    ticket_tag = create :ticket_tag

    group = automation_rule.condition_groups.first
    payload = {
      rule: {
        name: "Assign billing tag",
        description: nil,
        condition_groups_attributes: [
          {
            id: group.id,
            join_type: "and_operator",
            conditions_attributes: [
              {
                id: group.conditions.first.id,
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: nil
              }
            ]
          }
        ],
        actions_attributes: [
          {
            id: automation_rule.actions.first.id,
            name: "set_tags",
            tag_ids: [ticket_tag.id]
          }
        ]
      }
    }

    put api_v1_desk_automation_rule_url(automation_rule, payload), headers: headers(@user)
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Condition groups conditions value is required."
  end

  def test_that_rule_is_deleted
    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization

    assert_difference ["Desk::Automation::Rule.count"], -1 do
      assert_difference ["Desk::Automation::Condition.count", "Desk::Automation::Action.count"], -1 do
        delete api_v1_desk_automation_rule_url(automation_rule), headers: headers(@user)
      end
    end
    assert_response :ok
  end

  def test_that_delete_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization

    delete api_v1_desk_automation_rule_url(automation_rule), headers: headers(@user)
    assert_response :forbidden
  end

  def test_that_rule_details_are_shown
    automation_rule = create :automation_rule_with_data, name: "Billing", organization: @organization
    ticket = create(
      :ticket, organization: @organization,
      subject: "I have received my refund, done with the ticket, can be closed")
    create :execution_log_entry, rule: automation_rule, ticket: ticket

    get api_v1_desk_automation_rule_url(automation_rule), headers: headers(@user)
    assert_response :ok
    assert_not_nil json_body["rule"]
    assert_not_nil json_body["rule"]["execution_log_entries"]
  end

  def test_that_rule_is_created_for_email_to_agent_action
    payload = {
      rule: {
        name: "Assign billing tag",
        execute: "on_create",
        description: "assign #billing when subject contains refund",
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "and_operator",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "subject",
                verb: "contains",
                value: "Refund"
              }
            ]
          }
        ],
        actions_attributes: [
          {
            name: "email_to_agent",
            actionable_id: @user.id,
            actionable_type: "User",
            subject: "Your refund will be processed in 2 working days!",
            body: "Do not worry."
          }
        ]
      }
    }
    assert_difference ["Desk::Automation::Rule.count", "Desk::Automation::Condition.count",
"Desk::Automation::Action.count"] do
      post api_v1_desk_automation_rules_url(payload), headers: headers(@user)
    end
    assert_response :ok
  end
end
