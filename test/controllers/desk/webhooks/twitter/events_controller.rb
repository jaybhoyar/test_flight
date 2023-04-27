# frozen_string_literal: true

module Desk
  module Webhooks::Twitter
    class EventsController < ApplicationController
      respond_to :json
      skip_before_action :verify_authenticity_token, :load_organization

      def handle_event
        details = twitter_event_params.to_h
        details.merge!(event_type:)
        ::Desk::TwitterEventHandlerWorker.perform_async(details.deep_stringify_keys)
        render json: { status: "success" }, status: :ok
      end

      private

        def twitter_event_params
          event_keys = params.fetch(event_type, []).first&.keys
          event_keys += [
            user: {}, source: {}, target: {}, entities: {}, message_create: {}
          ]
          params.require(:event).permit(
            :for_user_id, :user_has_blocked, event_type => event_keys, users: {}
          )
        end

        def event_type
          @event_type ||= (params.keys.map(&:to_sym) & Desk::Twitter::Webhook::EVENTS).first.to_s
        end
    end
  end
end
