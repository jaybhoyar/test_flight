# frozen_string_literal: true

require "test_helper"

class Desk::Organizations::Seeder::RolesTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
  end

  def test_org_roles_are_successfully_seeded
    assert_difference "OrganizationRole.count", 2 do
      Desk::Organizations::Seeder::Roles.new(@organization).process
    end
  end

  def test_roles_are_not_duplicated_if_service_ran_twice
    Desk::Organizations::Seeder::Roles.new(@organization).process

    assert_equal 2, OrganizationRole.count

    assert_no_difference "OrganizationRole.count" do
      Desk::Organizations::Seeder::Roles.new(@organization).process
    end
  end
end
