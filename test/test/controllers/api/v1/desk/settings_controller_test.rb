# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::SettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    @user = create :user, organization: @organization

    sign_in @user

    host! test_domain(@organization.subdomain)
  end

  def test_show_success
    get api_v1_desk_setting_path, headers: headers(@user)

    assert_response :ok

    assert_equal [
      "auto_bcc", "automatic_redaction", "bcc_email",
      "custom_authentication", "organization", "tickets_email_footer", "tickets_email_footer_content"
    ], json_body["setting"].keys.sort

    assert_equal [
      "allow_anyone_to_submit_ticket",
      "api_key", "domain", "email_signin_enabled", "favicon_url",
      "id", "locale", "name", "subdomain", "url"
    ], json_body["setting"]["organization"].keys.sort
  end

  def test_that_bcc_fields_are_updated
    payload = { setting: { auto_bcc: true, bcc_email: "test@example.com" } }
    put api_v1_desk_setting_path, params: payload, headers: headers(@user)

    assert @organization.setting.reload.auto_bcc?
    assert_equal "test@example.com", @organization.setting.reload.bcc_email
  end
end
