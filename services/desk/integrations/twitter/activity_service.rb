# frozen_string_literal: true

module Desk::Integrations::Twitter
  class ActivityService
    attr_accessor :ticket, :activity_id, :details

    def initialize(ticket, activity_id, details = {}, options = {})
      @ticket = ticket
      @activity_id = activity_id
      @details = ActiveSupport::HashWithIndifferentAccess.new(details)
    end

    def create_activity
      return if ticket.blank?

      attach_twitter_activity_to_ticket
    end

    private

      def attach_twitter_activity_to_ticket
        ticket.twitter_activities.create!(twitter_activity_params)
      end

      def twitter_activity_params
        {
          for_user_id: details[:for_user_id],
          user_twitter_id: details[:user_twitter_id],
          activity_id:,
          event_type: details[:event_type],
          details:
        }
      end
  end
end
