# frozen_string_literal: true

require "test_helper"

class Desk::Customers::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user, :admin)
    @organization = @user.organization

    @customer_one = create(:user, organization: @organization, role: nil)
    @customer_two = create(:user, organization: @organization, role: nil)
  end

  def test_delete_customers_success
    service = Desk::Customers::DeletionService.new(customers)
    service.process
    assert_equal "Customers have been successfully removed.", service.response
  end

  def test_notes_deletion_along_with_customers
    create :note, user: @customer_one, description: "First note.", agent_id: @user.id
    create :note, user: @customer_two, description: "Second note.", agent_id: @user.id

    service = Desk::Customers::DeletionService.new(customers)
    assert_difference ["@customer_one.notes.count", "@customer_two.notes.count"], -1 do
      service.process
    end
    assert_equal "Customers have been successfully removed.", service.response
  end

  def test_tickets_destroyed_asynchronously_along_with_customers
    first_customer_ticket = create :ticket,
      organization: @organization,
      requester: @customer_one
    second_customer_ticket = create :ticket,
      organization: @organization,
      requester: @customer_two

    create :comment, ticket: first_customer_ticket
    create :comment, ticket: second_customer_ticket

    assert_difference -> { @organization.users.count } => -2,
      -> { Ticket.count } => -2,
      -> { Comment.count } => -2 do
        Desk::Customers::DeletionService.new(customers).process
        assert_enqueued_jobs 2
        perform_enqueued_jobs
      end
  end

  private

    def customers
      @organization.users.where(role: nil)
    end
end
