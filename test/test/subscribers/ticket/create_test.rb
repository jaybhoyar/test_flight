# frozen_string_literal: true

require "test_helper"

class Ticket::CreateTest < ActiveSupport::TestCase
  test "notification for ticket.create" do
    events = []
    ActiveSupport::Notifications.subscribe "ticket.create" do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end

    user = create :user
    organization = user.organization

    payload = {
      organization:,
      message: "Issue with login"
    }
    ActiveSupport::Notifications.instrument("ticket.create", payload)

    assert_equal 1, events.length
    assert_equal "ticket.create", events[0].name
    assert_equal "Issue with login", events[0].payload[:message]
  ensure
    ActiveSupport::Notifications.unsubscribe "ticket.create"
  end
end
