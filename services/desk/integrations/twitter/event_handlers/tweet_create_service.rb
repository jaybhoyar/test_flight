# frozen_string_literal: true

module Desk::Integrations::Twitter
  module EventHandlers
    class TweetCreateService
      attr_accessor :details, :tweet

      def initialize(details = {})
        @details = details
        @tweet = ::Desk::Twitter::Events::Tweet.new(details[:tweet_create_events].first, organization)
      end

      def perform
        ticket = process_tweet_event
        create_activity_record(ticket)
      end

      private

        def process_tweet_event
          return if duplicate_event?

          object = ::Desk::Integrations::Twitter::TicketHandlerService.new(*data, fetch_options).run
          ticket = new_ticket? ? object : object.ticket
        end

        def create_activity_record(ticket)
          details.merge!(user_twitter_id: tweet.from.customer_detail.twitter_id)
          Desk::Integrations::Twitter::ActivityService.new(ticket, tweet.message_id, details).create_activity
        end

        def data
          [
            tweet.from,
            tweet.subject,
            tweet.content,
            organization,
            tweet.in_reply_to_id,
            tweet.message_id,
            tweet.attachments
          ]
        end

        def fetch_options
          {
            new_ticket: new_ticket?,
            channel: "twitter",
            event_type: details[:event_type],
            channel_mode: "tweet",
            parent_comment:
          }
        end

        def organization
          @_organization ||= tw_account.organization
        end

        def tw_account
          @_tw_account ||= Desk::Twitter::Account.where(oauth_user_id: details[:for_user_id]).first
        end

        def duplicate_event?
          Desk::Twitter::Activity.where(activity_id: tweet.message_id).exists?
        end

        def new_ticket?
          tweet.in_reply_to_id.blank? || parent_comment.nil?
        end

        def parent_comment
          @_parent_comment ||= Comment.where.not(message_id: nil).where(message_id: tweet.in_reply_to_id).first
        end
    end
  end
end
