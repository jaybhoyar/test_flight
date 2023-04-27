# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Automation::RulePreviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    @user = create :user, organization: @organization
    sign_in(@user)

    @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
    @ticket_2 = create :ticket, organization: @organization, subject: "I am unable to use the application"
    @ticket_3 = create :ticket, organization: @organization, subject: "I am having issues with the plugin"
    @ticket_4 = create :ticket, organization: @organization, subject: "Where is help section in the app"
    @ticket_5 = create :ticket, organization: @organization, subject: "How to read the documentation, I need it urgently."

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_automation_rules", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def test_that_rule_is_previewed_in_correct_order_without_creating_the_record
    @ticket_1.update(created_at: Time.current - 1.minutes)
    @ticket_3.update(created_at: Time.current - 2.minutes)
    @ticket_4.update(created_at: Time.current - 3.minutes)
    @ticket_5.update(created_at: Time.current - 4.minutes)

    assert_no_difference ["Desk::Automation::Rule.count", "Desk::Core::Condition.count",
"Desk::Automation::Action.count"] do
      post api_v1_desk_automation_rule_previews_url(good_payload), headers: headers(@user)
    end
    assert_response :ok
    assert_equal 4, json_body["tickets"].count
    assert_equal @ticket_1.id, json_body["tickets"].first["id"]
    assert_equal @ticket_5.id, json_body["tickets"].last["id"]
  end

  def test_that_preview_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    post api_v1_desk_automation_rule_previews_url(good_payload), headers: headers(@user)
    assert_response :forbidden
  end

  def test_that_errors_are_shown_for_invalid_conditions
    assert_no_difference ["Desk::Automation::Rule.count", "Desk::Core::Condition.count",
"Desk::Automation::Action.count"] do
      post api_v1_desk_automation_rule_previews_url(bad_payload), headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Field is required."
  end

  private

    def good_payload
      {
        rule: {
          name: nil,
          execute: "on_create",
          description: "assign #billing when subject contains refund",
          condition_groups_attributes: [
            {
              join_type: "and_operator",
              conditions_join_type: "or_operator",
              conditions_attributes: [
                {
                  join_type: "or_operator",
                  field: "subject",
                  verb: "contains",
                  value: "help"
                },
                {
                  join_type: "or_operator",
                  field: "subject",
                  verb: "contains",
                  value: "issue"
                },
                {
                  join_type: "or_operator",
                  field: "subject",
                  verb: "contains",
                  value: "urgent"
                },
                {
                  join_type: "or_operator",
                  field: "subject",
                  verb: "contains",
                  value: "refund"
                }
              ]
            }
          ]
        }
      }
    end

    def bad_payload
      tag = create :tag

      {
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
                  field: nil,
                  verb: nil,
                  value: nil
                }
              ]
            }
          ]
        }
      }
    end
end
