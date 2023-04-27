# frozen_string_literal: true

require "test_helper"

module Desk
  class TwitterReplyServiceWorkerTest < ActiveSupport::TestCase
    def setup
      ticket = create(:ticket, requester: create(:user))
      @comment = create(:twitter_comment, :with_tweet, ticket:)
    end

    def test_event_handler_worker_perform
      Sidekiq::Testing.inline! do
        mock_object = mock("object")

        Desk::Ticket::Comment::TwitterReplyService.expects(:new).with(
          @comment.ticket,
          @comment).at_most_once.returns(mock_object)
        mock_object.expects(:process).at_most_once
        TwitterReplyServiceWorker.perform_async(@comment.id)
      end
    end

    def test_event_handler_worker_args
      Sidekiq::Testing.fake! do
        Sidekiq::Worker.clear_all
        TwitterReplyServiceWorker.perform_async(@comment.id)

        assert_equal 1, TwitterReplyServiceWorker.jobs.count
        worker = TwitterReplyServiceWorker.jobs.first

        assert_equal "Desk::TwitterReplyServiceWorker", worker["class"]
        assert_equal "default", worker["queue"]
        assert_equal ["#{@comment.id}"], worker["args"]
      end
    end
  end
end
