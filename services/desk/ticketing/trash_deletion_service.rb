# frozen_string_literal: true

class Desk::Ticketing::TrashDeletionService
  ALLOWED_MAX_DAYS_SINCE_TRASHED = 30

  def initialize
    @trash_tickets = ::Ticket.of_status("trash")
  end

  def process
    tickets_trashed_thirty_days_ago.destroy_all
  end

  private

    def tickets_trashed_thirty_days_ago
      @trash_tickets.all_updated_before_n_days(ALLOWED_MAX_DAYS_SINCE_TRASHED)
    end
end
