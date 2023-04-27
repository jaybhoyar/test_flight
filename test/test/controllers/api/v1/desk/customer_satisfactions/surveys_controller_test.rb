# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::CustomerSatisfactions::SurveysControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_index_success
    survey = create_survey
    get api_v1_desk_customer_satisfactions_surveys_url,
      headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["surveys"].size
  end

  def test_index_success_with_search
    survey = create_survey
    survey_params = {
      survey: {
        search_term: "Default"
      }
    }

    get api_v1_desk_customer_satisfactions_surveys_url, params: survey_params, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["surveys"].count
    assert_equal "Default Survey", json_body["surveys"][0]["name"]

    survey_params = {
      survey: {
        search_term: "Test"
      }
    }

    get api_v1_desk_customer_satisfactions_surveys_url, params: survey_params, headers: headers(@user)

    assert_response :ok
    assert_equal 0, json_body["surveys"].count
  end

  def test_index_success_with_pagination
    surveys = create_list(:another_survey, 25, organization: @organization, default: false)

    survey_params = {
      survey: {
        page_index: 1,
        page_size: 3
      }
    }

    get api_v1_desk_customer_satisfactions_surveys_url, params: survey_params, headers: headers(@user)

    assert_response :ok
    assert_equal 3, json_body["surveys"].count

    # with default pagination
    survey_params = {
      survey: {

      }
    }

    get api_v1_desk_customer_satisfactions_surveys_url, params: survey_params, headers: headers(@user)
    assert_response :ok
    assert_equal 15, json_body["surveys"].count
  end

  def test_new_success
    survey = create_survey
    get new_api_v1_desk_customer_satisfactions_survey_url,
      headers: headers(@user)

    assert_response :ok
    assert_equal 6, json_body["metadata"].size
  end

  def test_edit_success
    survey = create_survey
    get edit_api_v1_desk_customer_satisfactions_survey_url(survey),
      headers: headers(@user)

    assert_response :ok
    assert json_body["survey"]
    assert_equal survey.name, json_body["survey"]["name"]
    assert_equal survey.enabled, json_body["survey"]["enabled"]
    assert_equal 6, json_body["metadata"].size
  end

  def test_survey_create_success
    default_enabled_survey = create(:default_survey, organization: @organization)

    assert_difference "Desk::CustomerSatisfaction::Survey.count" do
      post api_v1_desk_customer_satisfactions_surveys_url,
        params: create_survey_params,
        headers: headers(@user)

      assert_response :created
    end
  end

  def test_survey_create_failure
    assert_no_difference "Desk::CustomerSatisfaction::Survey.count" do
      post api_v1_desk_customer_satisfactions_surveys_url,
        params: { survey: { name: "" } },
        headers: headers(@user)

      assert_response :unprocessable_entity
      assert_includes json_body["errors"], "Name can't be blank"
    end
  end

  def test_survey_update_success
    survey = create_survey
    update_survey_params = { survey: { name: "Primary Survey" } }

    patch api_v1_desk_customer_satisfactions_survey_url(survey),
      params: update_survey_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal "Primary Survey", survey.reload.name
  end

  def test_survey_update_failure
    survey = create_survey
    update_survey_params = { survey: { name: "" } }

    patch api_v1_desk_customer_satisfactions_survey_url(survey),
      params: update_survey_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name can't be blank"
  end

  def test_successfully_destroy_customer_satisfaction_survey
    survey = create(:default_survey, organization: @organization, enabled: false, default: false)

    assert_difference "Desk::CustomerSatisfaction::Survey.count", -1 do
      delete api_v1_desk_customer_satisfactions_survey_url(survey),
        headers: headers(@user)
    end
  end

  def test_fails_to_destroy_default_or_enabled_customer_satisfaction_survey
    enabled_survey = create(:another_survey, organization: @organization, default: false)
    default_survey = create_survey

    assert_no_difference "Desk::CustomerSatisfaction::Survey.count" do
      delete api_v1_desk_customer_satisfactions_survey_url(enabled_survey),
        headers: headers(@user)
      assert_equal ["Enabled survey cannot be deleted"], json_body["errors"]

      delete api_v1_desk_customer_satisfactions_survey_url(default_survey),
        headers: headers(@user)
      assert_equal ["Default survey cannot be deleted"], json_body["errors"]
    end
  end

  private

    def create_survey
      create(:default_survey, organization: @organization)
    end

    def create_survey_params
      {
        survey: {
          name: "Product Satisfaction Survey",
          enabled: true,
          email_state: "closed_ticket",
          acknowledgement_attributes: {
            text: "Thank you for your feedback"
          },
          questions_attributes: [{
            text: "How would you rate the value for moneyf the product",
            default: true,
            display_order: 1,
            point_scale: 3,
            scale_choices_attributes: [
              { text: "Extremely satisfied", display_order: 1 },
              { text: "Neither satisfied nor dissatisfied", display_order: 2 },
              { text: "Extremely dissatisfied", display_order: 3 },
            ]
          }]
        }
      }
    end
end
