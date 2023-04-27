# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class ColliderTest < ActiveSupport::TestCase
      def test_that_ticket_collider_is_valid
        ticket_collider = build :desk_ticket_collider
        assert ticket_collider.valid?
      end
    end
  end
end
