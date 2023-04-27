# frozen_string_literal: true

require "test_helper"

class TicketChannelTest < ActionCable::Channel::TestCase
  include ActionCable::TestHelper

  def setup
    @user = create :user
    @ticket = create :ticket

    stub_connection(current_user: @user)
  end

  def test_that_subscribe_works
    subscribe id: @ticket.id

    assert subscription.confirmed?
    assert_has_stream_for @ticket
  end

  def test_that_new_comment_type_message_is_broadcasted
    subscribe id: @ticket.id

    comment = create :comment, ticket: @ticket

    assert_broadcasts(@ticket, 1) do
      TicketChannel.broadcast_new_comment(comment)
    end
  end

  def test_that_ticket_collider_record_is_created
    collider = create :desk_ticket_collider, ticket: @ticket, user: @user

    subscribe id: @ticket.id

    broadcast_data = {
      type: "collide",
      collisions: [
        {
          id: collider.id,
          kind: "reply",
          user: {
            id: collider.user_id,
            name: collider.user.name,
            profile_image: collider.user.profile_image_url
          }
        }
      ]
    }
    assert_broadcast_on(@ticket, broadcast_data) do
      perform :mark, { "kind" => "reply" }
    end
  end

  def test_that_on_unsubscribe_collision_data_is_cleared
    create :desk_ticket_collider, ticket: @ticket, user: @user

    subscribe id: @ticket.id

    assert_difference "@ticket.ticket_colliders.count", -1 do
      assert_broadcast_on(@ticket, { type: "collide", collisions: [] }) do
        unsubscribe
      end
    end
  end

  def test_that_ticket_update_is_broadcasted
    subscribe id: @ticket.id

    assert_broadcasts(@ticket, 1) do
      TicketChannel.broadcast_ticket_updation(@ticket)
    end
  end
end
