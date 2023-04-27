# frozen_string_literal: true

require "test_helper"

class Api::V1::Outbound::UserPreviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create(:organization)
    @user = create(:user, email: "kyle@example.com", organization: @organization)

    sign_in(@user)

    @org_user_joe = create :user, email: "joe@example.com", organization: @organization
    @org_user_ken = create :user, email: "ken@example.com", organization: @organization
    @org_user_matt = create :user, email: "matt@example.com", organization: @organization
    @org_user_ray = create :user, email: "ray@example.com", organization: @organization

    host! test_domain(@organization.subdomain)
  end

  def test_that_rule_is_previewed_without_creating_the_record
    post api_v1_outbound_user_previews_url(good_payload), headers: headers(@user)

    assert_response :ok
    assert_equal 3, json_body["customers"].count
    array_of_customers = json_body["customers"].sort_by { |customer| customer["email"] }
    assert_equal @org_user_joe.id, array_of_customers[0]["id"]
    assert_equal @org_user_ray.id, array_of_customers[2]["id"]
  end

  def test_that_errors_are_shown_for_invalid_conditions
    post api_v1_outbound_user_previews_url(bad_payload), headers: headers(@user)

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
              field: "email",
              verb: "contains",
              value: "joe"
            },
            {
              join_type: "or_operator",
              field: "email",
              verb: "contains",
              value: "matt"
            },
            {
              join_type: "or_operator",
              field: "email",
              verb: "contains",
              value: "ray"
            }
          ]
        }
      }
    end

    def bad_payload
      {
        rule: {
          conditions_attributes: [
            {
              join_type: "and_operator",
              field: nil,
              verb: "is",
              value: nil
            }
          ]
        }
      }
    end
end
