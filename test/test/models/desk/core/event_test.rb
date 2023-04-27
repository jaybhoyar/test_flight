# frozen_string_literal: true

require "test_helper"

module Desk
  module Core
    class EventTest < ActiveSupport::TestCase
      def test_that_event_is_valid
        event = build :desk_core_event
        assert event.valid?
      end
    end
  end
end
