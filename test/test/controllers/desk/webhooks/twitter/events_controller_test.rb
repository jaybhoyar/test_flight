# frozen_string_literal: true

require "test_helper"

class Desk::Webhooks::Twitter::EventsControllerTest < ActionDispatch::IntegrationTest
  def test_enqueue_job
    handle_event_params = {
      for_user_id: "101", tweet_create_events: [{ id: "102" }],
      event: { for_user_id: "101", tweet_create_events: [{ id: "102" }] }
    }

    Sidekiq::Testing.fake! do
      Sidekiq::Worker.clear_all
      assert_difference "::Desk::TwitterEventHandlerWorker.jobs.count", 1 do
        post desk_webhooks_twitter_url, params: handle_event_params
      end
    end
  end

  def test_handle_event_success
    handle_event_params = {
      for_user_id: "101", tweet_create_events: [{ id: "102" }],
      event: { for_user_id: "101", tweet_create_events: [{ id: "102" }] }
    }

    Sidekiq::Testing.inline! do
      ::Desk::Integrations::Twitter::EventService.any_instance.expects(:handle_event).returns("result")

      post desk_webhooks_twitter_url, params: handle_event_params

      assert_response :ok
      assert_equal "handle_event", @controller.action_name
      assert_equal "tweet_create_events", @controller.send(:event_type).to_s
      assert_equal ["status"], json_body.keys
      assert_equal "success", json_body["status"]
    end
  end

  def test_handle_event_invalid_params
    handle_event_params = { invalid_param: "invalid_param" }
    assert_raises do
      post desk_webhooks_twitter_url, params: crc_params
    end
  end
end
