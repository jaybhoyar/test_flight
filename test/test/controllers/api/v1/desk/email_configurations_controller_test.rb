# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::EmailConfigurationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_create_email_configuration_success
    payload = { email_configuration: { email: "hello", from_name: "organization_name" } }
    post api_v1_desk_email_configurations_url(payload), headers: headers(@user)

    assert_response :ok
    assert_equal "Mailbox has been successfully created.", json_body["notice"]
    assert_equal "hello", EmailConfiguration.last.email
    assert_equal "hello#{@organization.email_domain_suffix}", EmailConfiguration.last.forward_to_email
  end

  def test_create_email_configurations_failure
    email_configuration = create_email_configuration
    payload = { email_configuration: { email: email_configuration.email.split(".#{@organization.subdomain}")[0] } }
    post api_v1_desk_email_configurations_url(payload), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_equal ["Email has already been taken"], json_body["errors"]
  end

  def test_update_email_configuration_success
    email_configuration = create_email_configuration

    payload = { email_configuration: { email: "help" } }
    patch api_v1_desk_email_configuration_url(email_configuration, payload), headers: headers(@user)

    email_configuration.reload
    assert_response :ok
    assert_equal "Email Configuration has been successfully updated.", json_body["notice"]
    assert_equal "help", email_configuration.email
    assert email_configuration.forward_to_email.start_with? "help."
    assert email_configuration.reply_to_email.start_with? "help."
  end

  def test_update_email_configuration_failure
    email_configuration = create_email_configuration
    new_email_configuration = create(:email_config_spinkart, organization: @organization)

    email_configuration.save!
    invalid_payload = {
      email_configuration: { email: new_email_configuration.email.split(".#{@organization.subdomain}")[0] }
    }
    patch api_v1_desk_email_configuration_url(
      email_configuration,
      invalid_payload),
      headers: headers(@user)

    email_configuration.reload

    assert_response :unprocessable_entity
    assert_equal ["Email has already been taken"], json_body["errors"]
  end

  def test_email_configurations_index_success
    email_configuration = create_email_configuration

    get api_v1_desk_email_configurations_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["email_configurations"].size
  end

  def test_that_email_configuration_is_destroyed
    email_configuration = create_email_configuration("help", false)

    assert_difference "EmailConfiguration.count", -1 do
      delete api_v1_desk_email_configuration_url(email_configuration.id), headers: headers(@user)
    end
    assert_response :success
  end

  private

    def create_email_configuration(email = "hello", primary = true)
      create(:email_configuration, email:, primary:, organization: @organization)
    end
end
