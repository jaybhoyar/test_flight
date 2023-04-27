# frozen_string_literal: true

require "test_helper"

module Desk
  module Automation
    class EventTest < ActiveSupport::TestCase
      def test_that_event_is_valid
        event = build :automation_event
        assert event.valid?
      end
    end
  end
end
