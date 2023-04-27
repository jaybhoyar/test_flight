# frozen_string_literal: true

require "test_helper"

class TicketsChannelTest < ActionCable::Channel::TestCase
  include ActionCable::TestHelper

  def setup
    @user = create :user

    stub_connection(current_user: @user)
  end

  def test_that_subscribe_works
    subscribe
    assert subscription.confirmed?
    assert_has_stream "tickets-#{@user.organization.subdomain}"
  end
end
