# frozen_string_literal: true

class Api::V1::Outbound::MessageEventsController < Api::V1::BaseController
  def index
    @outbound_message_events = Outbound::MessageEvent.all
  end
end
