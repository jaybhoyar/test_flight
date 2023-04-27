# frozen_string_literal: true

require "test_helper"

class Api::V1::Reports::Desk::SurveysControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization

    travel_to Time.zone.parse("2020-04-16 20:52:13")

    host! "#{@organization.subdomain}.lvh.me:3000"

    @view_permission = Permission.find_or_create_by(name: "reports.view_reports", category: "Reports")
    @manage_permission = Permission.find_or_create_by(name: "reports.manage_reports", category: "Reports")
    role = create :organization_role, permissions: [@view_permission, @manage_permission]
    @user.update(role:)
  end

  def teardown
    travel_back
  end

  test "index_without_authentication" do
    get api_v1_reports_desk_surveys_url
    assert_response 401
  end

  test "index without permissions" do
    role = create :organization_role
    @user.update(role:)

    date_range_params = { date_range: { type: "custom", from: "2020-04-05", to: "2020-04-11" } }
    get api_v1_reports_desk_surveys_url(date_range_params), headers: headers(@user)
    assert_response :forbidden
  end

  test "index_with_authentication" do
    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    get api_v1_reports_desk_surveys_url(date_range_params), headers: headers(@user)
    assert_response 200
  end

  test "index" do
    survey1, choice1, choice2, choice3 = setup_survey1
    survey2, choice4, choice5, choice6 = setup_survey2

    date_range_params = { date_range: { type: "custom", from: "2020-04-05", to: "2020-04-11" } }
    get api_v1_reports_desk_surveys_url(date_range_params), headers: headers(@user)
    assert_response 200

    assert_equal 2, json_body["surveys"].count

    assert_includes json_body["surveys"], {
      "id" => survey1.id, "name" => survey1.name, "question" => survey1.questions.first.text,
      "choices" => [
                                             { "name" => choice1.text, "count" => 2, "slug" => "happy" },
                                             { "name" => choice2.text, "count" => 1, "slug" => "neutral" },
                                             { "name" => choice3.text, "count" => 2, "slug" => "unhappy" }
                                            ]
    }

    assert_includes json_body["surveys"], {
      "id" => survey2.id, "name" => survey2.name, "question" => survey2.questions.first.text,
      "choices" => [
                                              { "name" => choice4.text, "count" => 2, "slug" => "happy" },
                                              { "name" => choice5.text, "count" => 2, "slug" => "neutral" }
                                            ]
    }
  end

  def setup_survey1
    choice1 = create(:default_question_scale_choice_1)
    choice2 = create(:default_question_scale_choice_2)
    choice3 = create(:default_question_scale_choice_3)

    scale_choices = [choice1, choice2, choice3]
    question = create(:default_question, scale_choices:)
    survey = create(:default_survey, organization: @organization, questions: [question])

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-07 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice1, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-08 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice2, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-09 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice3, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-09 10:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice1, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-11 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice3, ticket:)

    [ survey, choice1, choice2, choice3 ]
  end

  def setup_survey2
    choice4 = create(:default_question_scale_choice_1)
    choice5 = create(:default_question_scale_choice_2)
    choice6 = create(:default_question_scale_choice_3)

    scale_choices = [choice4, choice5, choice6]
    question = create(:default_question, scale_choices:)
    survey = create(:another_survey, organization: @organization, questions: [question])

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-07 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice5, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-20 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice5, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-09 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice5, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-11 10:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice4, ticket:)

    ticket = create(:ticket_with_email_config, organization: @organization)
    travel_to Time.zone.parse("2020-04-11 20:52:13")
    create(:desk_customer_satisfaction_survey_response, scale_choice: choice4, ticket:)

    [ survey, choice4, choice5, choice6 ]
  end
end
