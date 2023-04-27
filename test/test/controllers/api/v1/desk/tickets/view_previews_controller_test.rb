# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::ViewPreviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    @ticket_1 = create :ticket, organization: @organization, subject: "When can I expect my refund?"
    @ticket_2 = create :ticket, organization: @organization, subject: "I am unable to use the application"
    @ticket_3 = create :ticket, organization: @organization, subject: "I am having issues with the plugin"
    @ticket_4 = create :ticket, organization: @organization, subject: "Where is help section in the app"
    @ticket_5 = create :ticket, organization: @organization, subject: "How to read the documentation, I need it urgently."

    host! test_domain(@organization.subdomain)
  end

  def test_that_rule_is_previewed_without_creating_the_record
    post api_v1_desk_view_previews_url(good_payload), headers: headers(@user)

    assert_response :ok
    assert_equal 4, json_body["tickets"].count
  end

  def test_that_time_based_rule_is_previewed
    payload = {
      rule: {
        conditions_attributes: [
          {
            join_type: "and_operator",
            field: "ticket.status.hours.created",
            verb: "less_than",
            value: "2",
            kind: "time_based"
          }
        ]
      }
    }

    post api_v1_desk_view_previews_url(payload), headers: headers(@user)

    assert_response :ok
    assert_equal 5, json_body["tickets"].count
  end

  def test_that_errors_are_shown_for_invalid_conditions
    post api_v1_desk_view_previews_url(bad_payload), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Conditions field is required."
  end

  private

    def good_payload
      {
        rule: {
          conditions_attributes: [
            {
              join_type: "and_operator",
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
      }
    end

    def bad_payload
      tag = create :tag

      {
        rule: {
          conditions_attributes: [
            {
              join_type: "and_operator",
              field: nil,
              verb: nil,
              value: nil
            }
          ]
        }
      }
    end
end
