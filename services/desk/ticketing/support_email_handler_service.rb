# frozen_string_literal: true

module Desk::Ticketing
  class SupportEmailHandlerService
    attr_reader :support_email

    def initialize(support_email)
      @support_email = support_email
    end

    def run
      TicketHandlerService.new(support_email).run
    end
  end
end
