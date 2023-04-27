# frozen_string_literal: true

require "test_helper"
class Desk::Core::ConditionUsersFinderTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @outbound_message_1 = create :outbound_message
    @rule = create :desk_core_rule, organization: @organization

    @user_joe = create :user, email: "joe@example.com", organization: @organization
    @user_ray = create :user, email: "ray@example.com", organization: @organization
    @user_ken = create :user, email: "ken@example.com", organization: @organization
    @user_matt = create :user, email: "matt@example.com", organization: @organization
    @user_tim = create :user, email: "tim@example.in", organization: @organization
  end

  def test_users_for_email_with_is
    condition = create(:desk_core_condition, conditionable: @rule, field: "email", verb: "is", value: "joe@example.com")

    matching_users = get_matching_users_for(condition)
    assert_equal 1, matching_users.count
    assert_includes matching_users, @user_joe
  end

  def test_users_for_email_with_is_not
    condition = create(
      :desk_core_condition, conditionable: @rule, field: "email", verb: "is_not",
      value: "joe@example.com")

    matching_users = get_matching_users_for(condition)
    assert_equal 4, matching_users.count
    assert_includes matching_users, @user_ray
  end

  def test_users_for_email_with_contains
    condition = create(:desk_core_condition, conditionable: @rule, field: "email", verb: "contains", value: "joe")

    matching_users = get_matching_users_for(condition)
    assert_equal 1, matching_users.count
    assert_includes matching_users, @user_joe
  end

  def test_users_for_email_which_starts_with
    condition = create(:desk_core_condition, conditionable: @rule, field: "email", verb: "starts_with", value: "joe")

    matching_users = get_matching_users_for(condition)
    assert_equal 1, matching_users.count
    assert_includes matching_users, @user_joe
  end

  def test_users_for_email_which_ends_with
    condition = create(:desk_core_condition, conditionable: @rule, field: "email", verb: "ends_with", value: "in")

    matching_users = get_matching_users_for(condition)
    assert_equal 1, matching_users.count
    assert_includes matching_users, @user_tim
  end

  def test_users_for_last_sign_in_with_less_than
    @user_joe.update(last_sign_in_at: 5.days.ago.beginning_of_day)
    @user_ken.update(last_sign_in_at: 2.days.ago.beginning_of_day)
    @user_matt.update(last_sign_in_at: 8.days.ago.beginning_of_day)
    @user_ray.update(last_sign_in_at: 1.days.ago.beginning_of_day)

    condition = create :desk_core_condition, conditionable: @rule, field: "last_sign_in_at", verb: "less_than", value: "4"

    matching_users = get_matching_users_for(condition)
    assert_equal 2, matching_users.count
    assert_includes matching_users, @user_ken
  end

  def test_users_for_last_sign_in_with_greater_than
    @user_joe.update(last_sign_in_at: 5.days.ago.beginning_of_day)
    @user_ken.update(last_sign_in_at: 2.days.ago.beginning_of_day)
    @user_matt.update(last_sign_in_at: 8.days.ago.beginning_of_day)
    @user_ray.update(last_sign_in_at: 10.days.ago.beginning_of_day)

    condition = create :desk_core_condition, conditionable: @rule, field: "last_sign_in_at", verb: "greater_than", value: "2"

    matching_users = get_matching_users_for(condition)
    assert_equal 3, matching_users.count
    assert_includes matching_users, @user_matt
    assert_includes matching_users, @user_ray
  end

  def test_users_for_last_sign_in_with_is
    @user_joe.update(last_sign_in_at: 5.days.ago.beginning_of_day)
    @user_ken.update(last_sign_in_at: 2.days.ago.beginning_of_day)
    @user_matt.update(last_sign_in_at: 2.days.ago.beginning_of_day)
    @user_ray.update(last_sign_in_at: 10.days.ago.beginning_of_day)

    condition = create :desk_core_condition, conditionable: @rule, field: "last_sign_in_at", verb: "is", value: "2"

    matching_users = get_matching_users_for(condition)
    assert_equal 2, matching_users.count
    assert_includes matching_users, @user_matt
    assert_includes matching_users, @user_ken
  end

  def test_users_created_at_any_time
    condition = create :desk_core_condition, conditionable: @rule, field: "created_at", verb: "any_time", value: ""

    matching_users = get_matching_users_for(condition)
    assert_equal 5, matching_users.count
    assert_includes matching_users, @user_joe
  end

  def test_users_for_days_since_sign_up_with_is
    @user_joe.update(created_at: 2.days.ago.beginning_of_day)
    @user_ken.update(created_at: 2.days.ago.beginning_of_day)
    @user_matt.update(created_at: 2.days.ago.beginning_of_day)
    @user_ray.update(created_at: 10.days.ago.beginning_of_day)

    condition = create :desk_core_condition, conditionable: @rule, field: "created_at", verb: "is", value: "2"

    matching_users = get_matching_users_for(condition)
    assert_equal 3, matching_users.count
    assert_includes matching_users, @user_joe
    assert_includes matching_users, @user_matt
    assert_includes matching_users, @user_ken
  end

  def test_users_for_days_since_sign_up_with_less_than
    @user_joe.update(created_at: 7.days.ago.beginning_of_day)
    @user_ken.update(created_at: 1.days.ago.beginning_of_day)
    @user_matt.update(created_at: 15.days.ago.beginning_of_day)
    @user_ray.update(created_at: 10.days.ago.beginning_of_day)

    condition = create :desk_core_condition, conditionable: @rule, field: "created_at", verb: "less_than", value: "10"

    matching_users = get_matching_users_for(condition)
    assert_equal 2, matching_users.count
    assert_includes matching_users, @user_joe
    assert_includes matching_users, @user_ken
  end

  def test_users_for_days_since_sign_up_with_less_than
    @user_joe.update(created_at: 3.days.ago.beginning_of_day)
    @user_ken.update(created_at: 4.days.ago.beginning_of_day)
    @user_matt.update(created_at: 3.days.ago.beginning_of_day)
    @user_ray.update(created_at: 2.days.ago.beginning_of_day)

    condition = create :desk_core_condition, conditionable: @rule, field: "created_at", verb: "greater_than", value: "3"

    matching_users = get_matching_users_for(condition)
    assert_equal 1, matching_users.count
    assert_includes matching_users, @user_ken
  end

  def test_users_with_created_at_when_verb_is_any_time
    condition = create :desk_core_condition, conditionable: @rule, field: "created_at", verb: "any_time", value: ""

    matching_users = get_matching_users_for(condition)
    assert_equal 5, matching_users.count
    assert_includes matching_users, @user_matt
    assert_includes matching_users, @user_tim
  end

  private

    def get_matching_users_for(condition)
      ::Desk::Core::ConditionUsersFinder.new(
        condition.field, condition.verb,
        condition.value).matching_users_for(@organization)
    end
end
