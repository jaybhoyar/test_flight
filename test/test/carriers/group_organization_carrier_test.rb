# frozen_string_literal: true

require "test_helper"

class GroupOrganizationCarrierTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @group_carrier = GroupOrganizationCarrier.new(@organization)
  end

  def test_business_hour_options
    assert_equal @organization.business_hours.count, @group_carrier.business_hour_options.count
  end

  def test_user_options
    create :user, organization_role_id: create(:organization_role_admin).id, organization: @organization
    create :user, organization_role_id: create(:organization_role_agent).id, organization: @organization
    create :user, organization_role_id: nil, organization: @organization
    create :user, organization_role_id: create(:organization_role_agent).id, organization: @organization,
      deactivated_at: Time.current

    assert_equal 2, @group_carrier.user_options.count
  end
end
