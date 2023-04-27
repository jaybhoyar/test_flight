# frozen_string_literal: true

require "test_helper"

class Desk::CleanupStaleTicketCollidersWorkerTest < ActiveSupport::TestCase
  require "sidekiq/testing"

  def test_that_collider_objects_older_than_2_hours_are_cleared
    Sidekiq::Testing.inline!

    create :desk_ticket_collider, created_at: 3.hours.ago
    create :desk_ticket_collider, created_at: 2.hours.ago
    create :desk_ticket_collider, created_at: 1.hours.ago
    create :desk_ticket_collider, created_at: 5.minutes.ago

    assert_difference "Desk::Ticket::Collider.count", -3 do
      Desk::CleanupStaleTicketCollidersWorker.new.perform()
    end
  end
end
