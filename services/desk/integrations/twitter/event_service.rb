# frozen_string_literal: true

module Desk::Integrations::Twitter
  class EventService
    attr_accessor :details

    def initialize(details = {})
      @details = ActiveSupport::HashWithIndifferentAccess.new(details)
    end

    def handle_event
      case event_type
      when "tweet_create_events"
        Desk::Integrations::Twitter::EventHandlers::TweetCreateService.new(details).perform
      when "direct_message_events"
        Desk::Integrations::Twitter::EventHandlers::DirectMessageService.new(details).perform
      end
    end

    private

      def event_type
        @event_type ||= details[:event_type].to_s
      end
  end
end
