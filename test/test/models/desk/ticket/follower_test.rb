# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class FollowerTest < ActiveSupport::TestCase
      def test_that_follower_is_valid
        follower = build :desk_ticket_follower
        assert follower.valid?
      end

      def test_that_same_follower_is_not_allowed_on_a_ticket
        ethan = create :user
        ticket = create :ticket, organization: ethan.organization

        create :desk_ticket_follower, ticket: ticket, user: ethan
        follower = build :desk_ticket_follower, ticket: ticket, user: ethan

        refute follower.valid?
      end
    end
  end
end
