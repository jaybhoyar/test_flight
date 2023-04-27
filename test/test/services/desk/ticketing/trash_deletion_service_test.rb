# frozen_string_literal: true

require "test_helper"

class Desk::Ticketing::TrashDeletionServiceTest < ActiveSupport::TestCase
  def test_that_30_days_old_trashed_tickets_are_deleted
    ticket_1 = create :ticket, status: "open"
    ticket_2 = create :ticket, status: "open"
    ticket_3 = create :ticket, status: "open"
    ticket_4 = create :ticket, status: "open"
    ticket_5 = create :ticket, status: "open"
    ticket_6 = create :ticket, status: "closed"

    ticket_1.update(status: "trash", updated_at: 5.days.ago)
    ticket_2.update(status: "trash", updated_at: 10.days.ago)
    ticket_3.update(status: "trash", updated_at: 30.days.ago)
    ticket_4.update(status: "trash", updated_at: 40.days.ago)
    ticket_5.update(status: "trash", updated_at: 45.days.ago)

    assert_difference "Ticket.count", -3 do
      Desk::Ticketing::TrashDeletionService.new.process
    end
  end
end
