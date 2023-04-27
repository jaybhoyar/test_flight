# frozen_string_literal: true

require "test_helper"

class Desk::Integrations::Twitter::OauthServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:org_spinkart)
  end

  def test_oauth_base_url
    assert_equal "https://api.twitter.com/oauth", Desk::Integrations::Twitter::OauthService::OAUTH_BASE_URL
  end

  def test_request_token_success
    Desk::Twitter::Account.any_instance.expects(:request_token).at_most_once.returns(
      oauth_token: "sample_oauth_token", oauth_token_secret: "sample_oauth_token_secret", oauth_callback_confirmed: true
    )

    result = Desk::Integrations::Twitter::OauthService.new({}, @organization).request_token
    assert result[:success]
    assert_equal "https://api.twitter.com/oauth/authenticate?oauth_token=sample_oauth_token", result[:redirect_url]
  end

  def test_request_token_api_call
    stub_request(:post, "https://api.twitter.com/oauth/request_token").to_return(status: 200, body: "", headers: {})

    assert_raise TypeError do
      Desk::Integrations::Twitter::OauthService.new({}, @organization).request_token
      assert_requested :post, "https://api.twitter.com/oauth/request_token"
    end
  end

  def test_request_token_failure
    Desk::Twitter::Account.any_instance.expects(:request_token).at_most_once.returns(
      oauth_token: "sample_oauth_token",
      oauth_token_secret: "sample_oauth_token_secret",
      oauth_callback_confirmed: false
    )

    result = Desk::Integrations::Twitter::OauthService.new({}, @organization).request_token
    assert_not result[:success]
    assert_equal "An error occured while processing the request", result[:error]
  end

  def test_complete_oauth_success
    details = { oauth_token: "sample_oauth_token", oauth_verifier: "sample_oauth_verifier" }
    Desk::Twitter::Account.any_instance.expects(:request_token).at_most_once.returns(
      oauth_token: "sample_oauth_token", oauth_token_secret: "sample_oauth_token_secret", oauth_callback_confirmed: true
    )
    Desk::Twitter::Account.any_instance.expects(:request_access_token).at_most_once.with(details).returns(
      oauth_token: "new_oauth_token", oauth_token_secret: "new_oauth_token_secret", user_id: "123", screen_name: "screen_name"
    )
    Desk::Twitter::Account.any_instance.expects(:subscribe).at_most_once.returns("")
    Desk::Twitter::Account.any_instance.expects(:reload).at_most_once.returns("")
    Desk::Twitter::Account.any_instance.expects(:delete).at_most_once.returns("")

    Desk::Integrations::Twitter::OauthService.new({}, @organization).request_token
    Desk::Integrations::Twitter::OauthService.new(details, @organization).complete_oauth

    account = @organization.twitter_accounts.where(oauth_user_id: "123").first
    assert_equal "new_oauth_token", account.oauth_token
    assert_equal "new_oauth_token_secret", account.oauth_token_secret
    assert_equal "screen_name", account.screen_name
    assert_equal "test", account.env_name
  end

  def test_complete_oauth_success_without_access_token_request
    details = { oauth_token: "sample_oauth_token", oauth_verifier: "sample_oauth_verifier" }
    Desk::Twitter::Account.any_instance.expects(:request_token).at_most_once.returns(
      oauth_token: "sample_oauth_token", oauth_token_secret: "sample_oauth_token_secret", oauth_callback_confirmed: true
    )
    Desk::Twitter::Account.any_instance.expects(:subscribe).at_most_once.returns("")
    Desk::Twitter::Account.any_instance.expects(:reload).at_most_once.returns("")
    Desk::Twitter::Account.any_instance.expects(:delete).at_most_once.returns("")

    access_token = {
      oauth_token: "new_oauth_token",
      oauth_token_secret: "new_oauth_token_secret",
      user_id: "123",
      screen_name: "screen_name"
    }

    Desk::Integrations::Twitter::OauthService.new({}, @organization).request_token
    twitter_account = Desk::Twitter::Account.new
    twitter_account.expects(:request_access_token).never
    Desk::Integrations::Twitter::OauthService.new(details, nil, access_token).complete_oauth

    account = @organization.twitter_accounts.where(oauth_user_id: "123").first
    assert_equal "new_oauth_token", account.oauth_token
    assert_equal "new_oauth_token_secret", account.oauth_token_secret
    assert_equal "screen_name", account.screen_name
    assert_equal "test", account.env_name
  end

  def test_complete_oauth_raises_error_with_invalid_token
    details = { oauth_token: "sample_oauth_token", oauth_verifier: "sample_oauth_verifier" }

    assert_raises ::Desk::Integrations::Twitter::OauthService::TokenNotFoundError do
      Desk::Integrations::Twitter::OauthService.new(details, nil, {}).complete_oauth
    end
  end
end
