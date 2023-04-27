# frozen_string_literal: true

require "test_helper"

class Desk::Ticketing::UpdateMultipleServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    create_multiple_tickets
  end

  def test_that_tickets_are_trashed
    params = ActionController::Parameters.new({ status: "trash" })
    ticketing_update_multiple_service = Desk::Ticketing::UpdateMultipleService.new(tickets, params).process

    assert_equal "Tickets have been successfully moved to trash.", ticketing_update_multiple_service
  end

  def test_that_tickets_are_spammed
    params = ActionController::Parameters.new({ status: "spam" })
    ticketing_update_multiple_service = Desk::Ticketing::UpdateMultipleService.new(tickets, params).process

    assert_equal "Tickets have been successfully marked as spam.", ticketing_update_multiple_service
  end

  def test_that_agent_is_assigned
    ethan = create :user, organization: @organization, first_name: "Ethan"
    params = ActionController::Parameters.new({ agent_id: ethan.id })
    ticketing_update_multiple_service = Desk::Ticketing::UpdateMultipleService.new(tickets, params).process

    assert_equal "Tickets have been successfully updated.", ticketing_update_multiple_service
    assert_equal 5, Ticket.where(agent_id: ethan.id).count
  end

  private

    def create_multiple_tickets
      5.times do
        create :ticket, organization: @organization, requester: create(:user)
      end
    end

    def tickets
      @organization.tickets.all.to_a
    end
end
