# frozen_string_literal: true

require "test_helper"

class Tickets::ViewCarrierTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  def test_view_carrier_return_tickets_count
    user = create :user
    organization = user.organization

    create(:ticket, organization:)
    create(:ticket, organization:, agent_id: user.id)
    create(:ticket, organization:).update!(status: "spam")
    create(:ticket, organization:).update!(status: "trash")
    create(:ticket, organization:).update!(status: "closed")
    create(:ticket, organization:).update!(status: "resolved")

    carrier = Tickets::ViewCarrier.new(organization, user)

    assert_equal 3, carrier.tickets_count
    assert_equal 1, carrier.spam_tickets_count
    assert_equal 1, carrier.trash_tickets_count
    assert_equal 1, carrier.closed_tickets_count
    assert_equal 1, carrier.assigned_tickets_count
    assert_equal 2, carrier.unassigned_tickets_count
    assert_equal 1, carrier.tickets_assigned_to_current_user_count
    assert_equal 2, carrier.unresolved_tickets_count
    assert_equal 1, carrier.resolved_tickets_count
  end
end
