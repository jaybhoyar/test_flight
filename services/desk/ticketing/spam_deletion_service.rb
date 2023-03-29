# frozen_string_literal: true

class Desk::Ticketing::SpamDeletionService
  def process(allowed_max_days_since_spammed)
    spammed_tickets = ::Ticket.where(status: ::Ticket::DEFAULT_STATUSES[:spam])
    spammed_tickets.each do |ticket|
      if days_since_spammed(ticket) == allowed_max_days_since_spammed
        ticket.destroy
      end
    end
  end

  private

    def days_since_spammed(ticket)
      (Date.current - date_when_spammed(ticket).to_date).to_i
    end

    def date_when_spammed(ticket)
      spam_activity = ticket.activities.where(key: "activity.ticket.update.status").order(created_at: :desc).first
      return spam_activity.created_at if spam_activity.present?

      ticket.created_at
    end
end
