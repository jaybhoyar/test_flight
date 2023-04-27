# frozen_string_literal: true

require "test_helper"

class Desk::Twitter::AccountTest < ActiveSupport::TestCase
  BEARER_TOKEN = "SAMPLE_BEARER_TOKEN"
  TWITTER_CONFIG = Rails.application.secrets.twitter

  def test_active_scope
    account = create(:twitter_account)
    assert_equal 0, Desk::Twitter::Account.active.count

    account = create(:valid_twitter_account)
    assert_equal 1, Desk::Twitter::Account.active.count
  end

  def test_client_credentials
    account = create(:twitter_account)
    twitter_client = account.client

    assert_equal TWITTER_CONFIG[:api_key], twitter_client.consumer_key
    assert_equal TWITTER_CONFIG[:api_secret], twitter_client.consumer_secret
    assert_equal TWITTER_CONFIG[:access_token], twitter_client.access_token
    assert_equal TWITTER_CONFIG[:access_token_secret], twitter_client.access_token_secret
  end

  def test_app_client_credentials
    account = create(:twitter_account)
    twitter_client = account.app_client

    assert_equal TWITTER_CONFIG[:api_key], twitter_client.consumer_key
    assert_equal TWITTER_CONFIG[:api_secret], twitter_client.consumer_secret
    assert_nil twitter_client.access_token
    assert_nil twitter_client.access_token_secret
  end

  def test_request_token
    account = create(:twitter_account)
    Twitter::REST::Client.any_instance.expects(:request_token).with(TWITTER_CONFIG[:oauth_callback]).returns("token")
    assert_equal "token", account.request_token
  end

  def test_request_token_api_call
    account = create(:twitter_account)
    stub_request(:post, "https://api.twitter.com/oauth/request_token")
      .to_return(status: 200, body: "", headers: {})

    account.request_token

    assert_requested :post, "https://api.twitter.com/oauth/request_token", times: 1
  end

  def test_request_access_token
    account = create(:twitter_account)
    Twitter::REST::Client.any_instance.expects(:request_access_token).returns("access_token")
    assert_equal "access_token", account.request_access_token
  end

  def test_request_token_api_call
    account = create(:twitter_account)
    stub_request(:post, "https://api.twitter.com/oauth/access_token")
      .to_return(status: 200, body: "", headers: {})

    account.request_access_token

    assert_requested :post, "https://api.twitter.com/oauth/access_token", times: 1
  end

  def test_subscribe
    account = create(:valid_twitter_account)
    Twitter::REST::Client.any_instance.expects(:create_subscription).with(account.env_name).returns(true)
    assert account.subscribe
    assert_equal "active", account.reload.oauth_status
  end

  def test_subscribe_api_call
    account = create(:valid_twitter_account)
    stub_request(:post, "https://api.twitter.com/1.1/account_activity/all/test/subscriptions.json")
      .to_return(status: 200, body: "", headers: {})

    account.subscribe

    assert_requested :post, "https://api.twitter.com/1.1/account_activity/all/test/subscriptions.json", times: 1
  end

  def test_unsubscribe
    account = create(:valid_twitter_account)
    Twitter::REST::Client.any_instance.expects(:delete_subscription).with(
      account.env_name,
      account.oauth_user_id).returns(true)
    assert account.unsubscribe
    assert_equal "inactive", account.reload.oauth_status
  end

  def test_unsubscribe_api_call
    account = create(:valid_twitter_account)

    Twitter::REST::Client.any_instance.stubs(:token).returns(BEARER_TOKEN)
    stub_request(:delete, "https://api.twitter.com/1.1/account_activity/all/test/subscriptions/123456.json")
      .with(
        headers: {
          "Authorization" => "Bearer SAMPLE_BEARER_TOKEN",
          "Connection" => "close",
          "Host" => "api.twitter.com",
          "User-Agent" => "TwitterRubyGem/6.2.0"
        })
      .to_return(status: 200, body: "", headers: {})

    account.unsubscribe
    assert_requested :delete, "https://api.twitter.com/1.1/account_activity/all/test/subscriptions/123456.json",
      times: 1
  end

  def test_unsubscribe_inactive_account
    account = create(:valid_twitter_account)
    Twitter::REST::Client.any_instance.expects(:delete_subscription).with(account.env_name, account.oauth_user_id)
      .at_most_once.returns(true)

    assert account.unsubscribe
    assert_equal "inactive", account.reload.oauth_status

    # Try to unsubscribe already deactivated account, which should not make any call to twitter api.
    assert_nil account.unsubscribe
  end

  def test_uniqueness_of_screen_name
    create :valid_twitter_account
    account_2 = build :valid_twitter_account
    assert_not account_2.valid?
    assert_equal ["Screen name has already been taken"], account_2.errors.full_messages
  end
end
