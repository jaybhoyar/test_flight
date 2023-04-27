# frozen_string_literal: true

require "test_helper"

module Desk
  class DeleteTrashedTicketsWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      Sidekiq::Testing.fake!
    end

    def test_delete_tickets_after_thirty_days_in_trash
      ticket1 = create(:ticket)
      ticket2 = create(:ticket)
      ticket1.update!(status: "trash")
      ticket2.update!(status: "trash")
      expire_trash_tickets(ticket1)
      expire_trash_tickets(ticket2)

      assert_equal ::Ticket.count, 2
      DeleteTrashedTicketsWorker.new.perform
      assert_equal ::Ticket.count, 0
    end

    def expire_trash_tickets(ticket)
      ticket.created_at = ticket.created_at - 31.day
      ticket.updated_at = ticket.updated_at - 31.day
      ticket.save!
    end
  end
end
