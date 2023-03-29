# frozen_string_literal: true

module Desk::Integrations::Twitter
  module EventHandlers
    class DirectMessageService
      attr_accessor :details, :message

      def initialize(details = {})
        @details = details
        @message = ::Desk::Twitter::Events::DirectMessage.new(details, organization)
      end

      def perform
        ticket = process_direct_message_event
        create_activity_record(ticket)
      end

      private

        def process_direct_message_event
          return if dm_into_tickets_disabled? || duplicate_event?

          object = ::Desk::Integrations::Twitter::TicketHandlerService.new(*data, fetch_options).run
          ticket = new_ticket? ? object : object.ticket
        end

        def create_activity_record(ticket)
          details.merge!(user_twitter_id: message.fetch_user_details[:id])
          Desk::Integrations::Twitter::ActivityService.new(ticket, message.message_id, details).create_activity
        end

        def data
          [
            message.from,
            message.subject,
            message.content,
            organization,
            message.in_reply_to_id,
            message.message_id,
            message.attachments
          ]
        end

        def fetch_options
          {
            new_ticket: new_ticket?,
            channel: "twitter",
            event_type: details[:event_type],
            channel_mode: "direct_message",
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
          Desk::Twitter::Activity.where(activity_id: message.message_id).exists?
        end

        def dm_into_tickets_disabled?
          !tw_account.reload.convert_dm_into_ticket?
        end

        def new_ticket?
          recent_activity = Desk::Twitter::Activity
            .where(
              event_type: "direct_message_events",
              for_user_id: details[:for_user_id],
              user_twitter_id: message.fetch_user_details[:id]
                              )
            .order(created_at: :desc)
            .first

          recent_activity.blank? || exceeded_dm_ticket_threading_interval?(recent_activity)
        end

        def exceeded_dm_ticket_threading_interval?(activity)
          ((Time.current - activity.created_at) > tw_account.dm_ticket_threading_interval.minutes)
        end

        def parent_comment
          unless new_ticket?
            @_parent_comment ||= Comment.where.not(message_id: nil)
              .joins(:twitter_activities)
              .where(
                twitter_activities: {
                  event_type: "direct_message_events",
                  for_user_id: details[:for_user_id],
                  user_twitter_id: message.fetch_user_details[:id]
                }
                                    )
              .order("twitter_activities.created_at desc", "comments.created_at desc")
              .first
          end
        end
    end
  end
end
