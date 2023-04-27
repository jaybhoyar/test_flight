# frozen_string_literal: true

require "test_helper"
class PermissionSeederServiceTest < ActiveSupport::TestCase
  def test_permissions_are_successfully_seeded_and_not_duplicated
    assert_difference "Permission.count", 18 do
      PermissionSeederService.new.process
    end

    assert_no_difference "Permission.count" do
      PermissionSeederService.new.process
    end
  end
end
