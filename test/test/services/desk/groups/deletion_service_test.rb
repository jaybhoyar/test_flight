# frozen_string_literal: true

require "test_helper"

class Desk::Groups::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @organization = @user.organization
    @busienss_hour = create(:business_hour, organization: @organization)

    create_multiple_groups
  end

  def test_process_success
    groups_deletion_service = Desk::Groups::DeletionService.new(@organization.groups.first(2))

    assert_difference "Group.count", -2 do
      groups_deletion_service.process
    end

    assert_equal 1, @organization.groups.count
    assert groups_deletion_service.success?
  end

  def test_groups_are_unassigned_from_tickets
    group1, group2 = @organization.groups.first(2)
    ticket1 = create(:ticket, organization: @organization, group_id: group1.id)
    ticket2 = create(:ticket, organization: @organization, group_id: group2.id)

    groups_deletion_service = Desk::Groups::DeletionService.new([group1, group2])
    groups_deletion_service.process
    ticket1.reload
    ticket2.reload

    assert_nil ticket1.group_id
    assert_nil ticket2.group_id
  end

  private

    def create_multiple_groups
      3.times do
        create(:group, organization: @organization, business_hour: @busienss_hour)
      end
    end
end
