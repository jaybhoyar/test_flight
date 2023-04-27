# frozen_string_literal: true

require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @ticket_permission = create(:permission, sequence: 1)
  end

  def test_permission_should_be_valid
    assert @ticket_permission.valid?
  end

  def test_name_should_not_be_blank
    permission = Permission.new

    assert_not permission.valid?
    assert permission.errors.added?(:name, "can't be blank")
  end

  def test_should_not_create_permission_with_duplicate_name
    permission = build :permission, name: @ticket_permission.name, category: @ticket_permission.category

    assert_not permission.valid?
    assert permission.errors.added?(:name, "has already been taken")
  end
end
