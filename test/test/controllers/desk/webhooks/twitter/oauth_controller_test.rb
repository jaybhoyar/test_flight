# frozen_string_literal: true

require "test_helper"

class Desk::Webhooks::Twitter::OauthControllerTest < ActionDispatch::IntegrationTest
  def test_callback_success
    twitter_account = create(:twitter_account_spinkart)
    callback_params = { oauth_token: "twitter_token", oauth_verifier: "twitter_verifier" }

    Desk::Twitter::Account.expects(:where).at_most_once.returns([twitter_account])
    Desk::Twitter::Account.any_instance.expects(:request_access_token).at_most_once.returns({})

    ::Desk::Integrations::Twitter::OauthService
      .any_instance
      .expects(:complete_oauth)
      .at_most_once.returns(twitter_account.organization)

    get desk_webhooks_twitter_oauth_callback_url, params: callback_params

    assert_response 302
    assert_equal "callback", @controller.action_name
    assert_redirected_to "#{twitter_account.organization.root_url}desk/settings/twitter_accounts"
  end

  def test_callback_invalid_params
    callback_params = { invalid_param: "invalid_param" }

    get desk_webhooks_twitter_oauth_callback_url, params: callback_params

    assert_redirected_to app_secrets[:auth_app][:url]
  end
end
