# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Twitter::AccountsControllerTest < ActionDispatch::IntegrationTest
  BEARER_TOKEN = "SAMPLE_BEARER_TOKEN"

  def setup
    @user = create(:user)
    @organization = @user.organization
    @group = create(:group)
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_twitter_index_success
    twitter_account = create(:valid_twitter_account, organization: @organization)

    get api_v1_desk_twitter_accounts_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["twitter_accounts"].size
  end

  def test_twitter_index_success_with_inactive_account
    twitter_account_1 = create(:valid_twitter_account, organization: @organization)

    get api_v1_desk_twitter_accounts_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["twitter_accounts"].size
  end

  def test_delete_twitter_account_success
    twitter_account = create(:valid_twitter_account, organization: @organization)

    Twitter::REST::Client.any_instance.stubs(:token).returns(BEARER_TOKEN)

    stub_request(:delete, "https://api.twitter.com/1.1/account_activity/all/test/subscriptions/123456.json")
      .with(
        headers: {
          "Authorization" => "Bearer SAMPLE_BEARER_TOKEN",
          "Connection" => "close",
          "Host" => "api.twitter.com",
          "User-Agent" => "TwitterRubyGem/6.2.0"
        })
      .to_return(status: 204, body: "", headers: {})

    delete api_v1_desk_twitter_account_url(twitter_account.id), headers: headers(@user)

    assert_requested :delete, "https://api.twitter.com/1.1/account_activity/all/test/subscriptions/123456.json",
      times: 1

    assert_response :ok
    assert_equal 0, Desk::Twitter::Account.count
    assert_equal "Account has been successfully unlinked.", json_body["notice"]
  end

  def test_show_twitter_account_success
    twitter_account = create(:valid_twitter_account, organization: @organization, convert_dm_into_ticket: false)

    get api_v1_desk_twitter_account_url(twitter_account), headers: headers(@user)

    assert_response :ok
    assert json_body["twitter_account"]
    assert_equal %w(convert_dm_into_ticket id screen_name), json_body["twitter_account"].keys.sort
  end

  def test_update_twitter_account_success
    twitter_account = create(:valid_twitter_account, organization: @organization, convert_dm_into_ticket: false)

    payload = { account: { convert_dm_into_ticket: true } }

    assert_not twitter_account.convert_dm_into_ticket

    patch api_v1_desk_twitter_account_url(twitter_account),
      params: payload,
      headers: headers(@user)

    assert_equal "Twitter preferences have been successfully updated.", json_body["notice"]
    assert twitter_account.reload.convert_dm_into_ticket
  end

  private

    def create_twitter_account
      create(:twitter_account, organization: @organization)
    end
end
