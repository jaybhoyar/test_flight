# frozen_string_literal: true

require "test_helper"

module Desk
  class TwitterEventHandlerWorkerTest < ActiveSupport::TestCase
    def test_event_handler_worker_perform
      Sidekiq::Testing.inline! do
        mock_object = mock("object")

        ::Desk::Integrations::Twitter::EventService.expects(:new).with("test" => true).at_most_once.returns(mock_object)
        mock_object.expects(:handle_event).at_most_once

        TwitterEventHandlerWorker.perform_async({ test: true }.deep_stringify_keys)
      end
    end

    def test_event_handler_worker_args
      Sidekiq::Testing.fake! do
        Sidekiq::Worker.clear_all
        TwitterEventHandlerWorker.perform_async({ test: true }.deep_stringify_keys)

        assert_equal 1, TwitterEventHandlerWorker.jobs.count
        worker = TwitterEventHandlerWorker.jobs.first

        assert_equal "Desk::TwitterEventHandlerWorker", worker["class"]
        assert_equal "default", worker["queue"]
        assert_equal [{ "test" => true }], worker["args"]
      end
    end
  end
end
