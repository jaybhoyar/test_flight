# frozen_string_literal: true

require "test_helper"

class Desk::Ticketing::SpamDeletionServiceTest < ActiveSupport::TestCase
  def test_that_spammed_tickets_are_destroyed
    ticket_1 = create :ticket, status: "spam"
    ticket_2 = create :ticket, status: "spam"
    ticket_3 = create :ticket, status: "spam"
    ticket_4 = create :ticket, status: "spam", created_at: 5.days.ago
    ticket_5 = create :ticket, status: "spam", created_at: 10.days.ago
    ticket_6 = create :ticket, status: "closed", created_at: 10.days.ago

    create :activity, trackable: ticket_1, key: "activity.ticket.update.status", created_at: 5.days.ago
    create :activity, trackable: ticket_2, key: "activity.ticket.update.status", created_at: 10.days.ago
    create :activity, trackable: ticket_3, key: "activity.ticket.update.priority", created_at: 15.days.ago

    assert_difference "Ticket.count", -2 do
      Desk::Ticketing::SpamDeletionService.new.process(10)
    end
  end
end
