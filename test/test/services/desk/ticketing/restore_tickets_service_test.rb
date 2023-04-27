# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class RestoreTicketsServiceTest < ActiveSupport::TestCase
    def setup
      @organization_role = create :organization_role_agent
      @user = create(:user, role: @organization_role)
      @organization = @user.organization
      @ticket = create(:ticket, organization: @organization)
      User.current = @user
    end

    def test_ticket_unspammed
      @ticket.update!(status: "spam")
      assert_equal "Ticket has been successfully restored.",
        Desk::Ticketing::RestoreTicketsService.new([@ticket]).process
    end
  end
end
