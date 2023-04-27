# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Desk::Ticketing
  class SupportEmailHandlerServiceTest < ActiveSupport::TestCase
    def setup
      @email_configuration = create(:email_configuration)
      @organization = @email_configuration.organization
      @from_email = "mikel@test.lindsaar.net"
      @subject = "Unable to generate Invoice"
      @email_body = %{ Hi
        I am not able to generate an invoice for June 2019.
        Please help.

        Mike
      }

      @mail = Mail.new
      @mail.from = @from_email
      @mail.to = @email_configuration.forward_to_email
      @mail.subject = @subject
      @mail.body = @email_body

      @support_email = SupportEmail.new(@mail)

      @support_email_handler_service = SupportEmailHandlerService.new(@support_email)
    end

    def test_run
      # mock = MiniTest::Mock.new
      # Desk::Ticketing::TicketHandlerService.stub(:new, mock)

      # mock.expect(:run,  nil, ["LOGIN", "user", "password"])

      # @support_email_handler_service.run
    end
  end
end
