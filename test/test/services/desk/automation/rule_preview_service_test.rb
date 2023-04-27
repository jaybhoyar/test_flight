# frozen_string_literal: true

require "test_helper"
class Desk::Automation::RulePreviewServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = rule = create :automation_rule, :on_ticket_create, organization: @organization
    @condition_group = create :automation_condition_group, rule: @rule

    user_aditya = create :user, email: "aditya.varma@example.com", organization: @organization
    user_rohit = create :user, email: "rohit.sharma@example.com", organization: @organization
    user_virat = create :user, email: "virat.shetty@example.com", organization: @organization

    @ticket_1 = create :ticket, requester: user_aditya, organization: @organization, subject: "When can I expect my refund?"
    @ticket_2 = create :ticket, requester: user_aditya, organization: @organization, subject: "I am unable to use the application"
    @ticket_3 = create :ticket, requester: user_rohit, organization: @organization, subject: "I am having issues with the plugin"
    @ticket_4 = create :ticket, subject: "ticket 4"
  end

  def test_that_matching_tickets_are_returned
    service = build_service_obj(good_payload)
    assert_equal 2, service.matching_tickets.count
  end

  def test_that_matching_tickets_are_returned_with_existing_rule_with_changes
    condition = create :desk_core_condition, conditionable: @condition_group, field: "subject", verb: "contains", value: "expect"

    payload = {
      condition_groups_attributes: [
        {
          join_type: "and_operator",
          conditions_join_type: "or_operator",
          conditions_attributes: [
            {
              join_type: "or_operator",
              field: "subject",
              verb: "contains",
              value: "expect"
            },
            {
              join_type: "or_operator",
              field: "subject",
              verb: "contains",
              value: "issue"
            }
          ]
        }
      ]
    }
    service = build_service_obj(payload)
    assert_equal 2, service.matching_tickets.count
  end

  def test_that_conditions_are_valid
    service = build_service_obj(good_payload)
    assert service.valid_conditions?
  end

  def test_that_conditions_are_invalid
    service = build_service_obj(bad_payload)
    assert_not service.valid_conditions?
  end

  def test_that_errors_are_shown
    service = build_service_obj(bad_payload)
    assert_includes service.error_messages, "Field is required."
  end

  def test_that_errors_are_not_shown_when_conditions_are_valid
    service = build_service_obj(good_payload)
    assert_empty service.error_messages
  end

  private

    def build_service_obj(payload)
      Desk::Automation::RulePreviewService.new(@organization, payload)
    end

    def good_payload
      {
        name: nil,
        description: "assign #billing when subject contains refund",
        events_attributes: [
          { name: "created" }
        ],
        condition_groups_attributes: [
          {
            join_type: "and_operator",
            conditions_join_type: "or_operator",
            conditions_attributes: [
              {
                join_type: "or_operator",
                field: "subject",
                verb: "contains",
                value: "Refund"
              },
              {
                join_type: "or_operator",
                field: "subject",
                verb: "contains",
                value: "issue"
              }
            ]
          }
        ]
      }
    end

    def bad_payload
      {
        name: "Assign billing tag",
        description: "assign #billing when subject contains refund",
        events_attributes: [
          { name: "created" }
        ],
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
              },
              {
                join_type: "or_operator",
                field: nil,
                verb: nil,
                value: nil
              }
            ]
          }
        ]
      }
    end
end
