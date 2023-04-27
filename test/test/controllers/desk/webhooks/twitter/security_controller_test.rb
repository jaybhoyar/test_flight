# frozen_string_literal: true

require "test_helper"

class Desk::Webhooks::Twitter::SecurityControllerTest < ActionDispatch::IntegrationTest
  CRC_TOKEN = "Y2M3MjljYWItOWEwYS00ZjZlL"
  RESPONSE_TOKEN = "sha256=HzBnG5ZVTxVW6PztM9reaofpc2UdNqXO/HujPJtoPh8="

  def test_crc_check_success
    crc_params = { crc_token: CRC_TOKEN }
    get desk_webhooks_twitter_url, params: crc_params

    assert_response :ok
    assert_equal "crc_check", @controller.action_name
    assert_equal ["response_token"], json_body.keys
    assert_equal RESPONSE_TOKEN, json_body["response_token"]
  end

  def test_crc_check_invalid_params
    crc_params = { invalid_param: "invalid_param" }
    get desk_webhooks_twitter_url, params: crc_params
    assert_response :error
  end
end
