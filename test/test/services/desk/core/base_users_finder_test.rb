# frozen_string_literal: true

require "test_helper"
class Desk::Core::BaseUsersFinderTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create :desk_core_rule, organization: @organization
    @condition = create :desk_core_condition, conditionable: @rule, field: "email", verb: "contains", value: "joe"

    user = create(:user, organization: @organization)

    @user_matt = create :user, email: "matt@example.com", organization: @organization
    @user_tim = create :user, email: "tim@example.in", organization: @organization
  end

  def test_valid_verb
    service = get_service
    assert service.valid_verb?

    service = ::Desk::Core::BaseUsersFinder.new(@condition.field, "invalid_verb", @condition.value)
    assert_not service.valid_verb?
  end

  def test_arel_methods
    service = get_service

    assert_nothing_raised do
      service.users
      service.organizations
    end
  end

  private

    def get_service
      ::Desk::Core::BaseUsersFinder.new(@condition.field, @condition.verb, @condition.value)
    end
end
