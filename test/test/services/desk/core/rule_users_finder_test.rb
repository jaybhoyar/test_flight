# frozen_string_literal: true

require "test_helper"
class Desk::Core::RuleUsersFinderTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @outbound_message_1 = create :outbound_message
    @rule = create :desk_core_rule, organization: @organization

    @user_joe = create :user, email: "joe@example.com", organization: @organization
    @user_ray = create :user, email: "ray@example.com", organization: @organization
    @user_ken = create :user, email: "ken@example.com", organization: @organization
    @user_matt = create :user, email: "matt@example.com", organization: @organization
  end

  def test_that_rule_without_conditions_matches_with_all_users
    assert_equal 4, get_matching_users.count
  end

  def test_that_deactivated_users_are_not_matched
    @user_matt.deactivate!

    assert_equal 3, get_matching_users.count
  end

  def test_users_for_email_with_is
    create(
      :desk_core_condition, join_type: "and_operator", conditionable: @rule, field: "email", verb: "is",
      value: "joe@example.com")

    create(
      :desk_core_condition, conditionable: @rule, field: "email", verb: "contains",
      value: "joe")

    matching_users = get_matching_users
    assert_equal 1, matching_users.count
  end

  def test_users_for_email_with_is_not
    create(
      :desk_core_condition, join_type: "and_operator", conditionable: @rule, field: "email", verb: "is_not",
      value: "joe@example.com")

    create(
      :desk_core_condition, conditionable: @rule, field: "email", verb: "is_not",
      value: "ken@example.com")

    matching_users = get_matching_users
    assert_equal 2, matching_users.count
  end

  def test_users_for_email_with_contains
    create(
      :desk_core_condition, conditionable: @rule, field: "email", verb: "contains",
      value: "ray")

    create(
      :desk_core_condition, join_type: "and_operator", conditionable: @rule, field: "email", verb: "is_not",
      value: "matt")

    matching_users = get_matching_users
    assert_equal 1, matching_users.count
  end

  def test_users_with_last_sign_in_greater_than
    @user_joe.update(last_sign_in_at: 5.days.ago.beginning_of_day)
    @user_ray.update(last_sign_in_at: 2.days.ago.beginning_of_day)
    @user_ken.update(last_sign_in_at: 3.days.ago.beginning_of_day)
    @user_matt.update(last_sign_in_at: 10.days.ago.beginning_of_day)

    create(
      :desk_core_condition, join_type: "and_operator",
      conditionable: @rule, field: "last_sign_in_at", verb: "greater_than", value: "2")

    create(
      :desk_core_condition, conditionable: @rule,
      field: "last_sign_in_at", verb: "less_than", value: "7")

    matching_users = get_matching_users
    assert_equal 2, matching_users.count
  end

  def test_users_with_last_sign_in_is
    @user_joe.update(last_sign_in_at: 5.days.ago.beginning_of_day)
    @user_ray.update(last_sign_in_at: 4.days.ago.beginning_of_day)
    @user_ken.update(last_sign_in_at: 4.days.ago.beginning_of_day)
    @user_matt.update(last_sign_in_at: 4.days.ago.beginning_of_day)

    create(
      :desk_core_condition, join_type: "and_operator",
      conditionable: @rule, field: "last_sign_in_at", verb: "is", value: "4")

    matching_users = get_matching_users
    assert_equal 3, matching_users.count
  end

  def test_users_with_sign_up_is
    @user_joe.update(created_at: 5.days.ago.beginning_of_day)
    @user_ken.update(created_at: 5.days.ago.beginning_of_day)
    @user_matt.update(created_at: 1.days.ago.beginning_of_day)
    @user_ray.update(created_at: 4.days.ago.beginning_of_day)

    create(
      :desk_core_condition, join_type: "and_operator",
      conditionable: @rule, field: "created_at", verb: "is", value: "5")

    matching_users = get_matching_users
    assert_equal 2, matching_users.count
  end

  def test_users_with_sign_up_less_than
    @user_joe.update(created_at: 5.days.ago.beginning_of_day)
    @user_ken.update(created_at: 2.days.ago.beginning_of_day)
    @user_matt.update(created_at: 1.days.ago.beginning_of_day)
    @user_ray.update(created_at: 4.days.ago.beginning_of_day)

    create(
      :desk_core_condition, join_type: "and_operator",
      conditionable: @rule, field: "created_at", verb: "less_than", value: "4")

    matching_users = get_matching_users
    assert_equal 3, matching_users.count
  end

  def test_users_with_sign_up_greater_than
    @user_joe.update(created_at: 3.days.ago.beginning_of_day)
    @user_ray.update(created_at: 2.days.ago.beginning_of_day)
    @user_ken.update(created_at: 1.days.ago.beginning_of_day)
    @user_matt.update(created_at: 3.days.ago.beginning_of_day)

    create(
      :desk_core_condition, join_type: "and_operator",
      conditionable: @rule, field: "created_at", verb: "greater_than", value: "2")

    matching_users = get_matching_users
    assert_equal 2, matching_users.count
  end

  def test_users_for_email_with_contains_using_or_operator
    create(
      :desk_core_condition, join_type: "or_operator", conditionable: @rule, field: "email",
      verb: "contains", value: "joe")

    create(
      :desk_core_condition, join_type: "or_operator", conditionable: @rule, field: "email",
      verb: "contains", value: "ray")

    matching_users = get_matching_users
    assert_equal 2, matching_users.count
  end

  def test_users_for_email_with_contains_using_mix_of_operator
    create(
      :desk_core_condition, join_type: "and_operator", conditionable: @rule, field: "email",
      verb: "is_not", value: "joe@example.com")

    create(
      :desk_core_condition, join_type: "or_operator", conditionable: @rule, field: "email",
      verb: "contains", value: "ray")

    matching_users = get_matching_users
    assert_equal 3, matching_users.count
    assert_not_includes matching_users, @user_joe
  end

  private

    def get_matching_users
      ::Desk::Core::RuleUsersFinder.new(@rule.reload).matching_users
    end
end
