# frozen_string_literal: true

require "test_helper"

class Desk::Twitter::WebhookTest < ActiveSupport::TestCase
  BEARER_TOKEN = "SAMPLE_BEARER_TOKEN"

  def test_valid_twitter_webhook
    valid_twitter_webhook = create(:twitter_webhook)
    assert valid_twitter_webhook.valid?
  end

  def test_invalid_twitter_webhook_url
    invalid_twitter_webhook = create(:twitter_webhook)
    invalid_twitter_webhook.url = nil
    assert_raise(ActiveRecord::RecordInvalid) do
      invalid_twitter_webhook.save!
    end
  end

  def test_invalid_twitter_webhook_env_name
    invalid_twitter_webhook = create(:twitter_webhook)
    invalid_twitter_webhook.env_name = nil
    assert_raise(ActiveRecord::RecordInvalid) do
      invalid_twitter_webhook.save!
    end
  end

  def test_trigger_crc_service_call
    webhook = create(:valid_twitter_webhook)

    Desk::Integrations::Twitter::WebhookService.any_instance.expects(:trigger_crc).returns("crc_triggered")
    assert_equal "crc_triggered", webhook.trigger_crc
  end

  def test_trigger_crc_twitter_api_calls
    webhook = create(:valid_twitter_webhook)

    Twitter::REST::Client.any_instance.stubs(:token).returns(BEARER_TOKEN)
    stub_request(:put, "https://api.twitter.com/1.1/account_activity/all/test/webhooks/123456.json")
      .to_return(status: 200, body: "", headers: {})

    webhook.trigger_crc
    assert_requested :put, "https://api.twitter.com/1.1/account_activity/all/test/webhooks/123456.json", times: 1
  end

  def test_create_webhook_service_call
    webhook = create(:twitter_webhook)

    Desk::Integrations::Twitter::WebhookService.any_instance.expects(:create_webhook).returns(
      id: "123456", valid: true, created_timestamp: "2020-01-08 10:11:24 +0000"
    )

    webhook.register
    webhook.reload

    assert_equal "123456", webhook.webhook_id
    assert webhook.valid_webhook
    assert_equal "2020-01-08 10:11:24 +0000", webhook.timestamp
  end

  def test_register_twitter_api_calls
    webhook = create(:twitter_webhook)

    Twitter::REST::Client.any_instance.stubs(:token).returns(BEARER_TOKEN)

    stub_request(:post, "https://api.twitter.com/1.1/account_activity/all/test/webhooks.json")
      .with(body: { "url" => "https://sample.com/desk/webhooks/twitter" })
      .to_return(status: 200, body: "", headers: {})

    assert_raises(TypeError) { webhook.register }
    assert_requested :post, "https://api.twitter.com/1.1/account_activity/all/test/webhooks.json", times: 1
  end

  def test_delete_webhook_service_call
    webhook = create(:valid_twitter_webhook)

    Desk::Integrations::Twitter::WebhookService.any_instance.expects(:delete_webhook).returns("")

    webhook.deregister
    webhook.reload

    assert_not webhook.valid_webhook
    assert_nil webhook.webhook_id
    assert_nil webhook.timestamp
  end

  def test_deregister_twitter_api_calls
    webhook = create(:valid_twitter_webhook)

    Twitter::REST::Client.any_instance.stubs(:token).returns(BEARER_TOKEN)

    stub_request(:delete, "https://api.twitter.com/1.1/account_activity/all/test/webhooks/123456.json")
      .to_return(status: 200, body: "", headers: {})

    webhook.deregister
    assert_requested :delete, "https://api.twitter.com/1.1/account_activity/all/test/webhooks/123456.json", times: 1
  end
end
