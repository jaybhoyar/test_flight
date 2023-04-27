# frozen_string_literal: true

require "test_helper"

class Outbound::ConditionTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @rule = create(:outbound_message_rule)
    @ticket = create(:ticket, organization: @rule.organization)
    @user_joe = create :user, organization: @organization
    @user_matt = create :user, organization: @organization
    @user_ken = create :user, organization: @organization

    @condition_1 = create(:outbound_condition, conditionable: @rule)
    @condition_2 = create(:outbound_condition, conditionable: @rule)
  end

  test "valid rule" do
    assert @condition_1.valid?
  end

  test "invalid rule" do
    @condition_1.join_type = ""
    @condition_1.verb = ""
    assert_not @condition_1.valid?
    assert_includes @condition_1.errors.messages[:join_type], " is not a valid join operation."
    assert_includes @condition_1.errors.messages[:verb], " is not a valid verb."
  end

  test "matching_users - email equals" do
    email = "joe@example.com"
    @user_joe.email = email
    @user_joe.save!

    rule = create(:automation_rule, name: "Finding users with email", organization: @rule.organization)
    condition = create(:outbound_condition, conditionable: rule, field: "email", verb: "is", value: email)

    assert condition.match_user?(@user_joe)
  end

  test "matching_users - email not equals" do
    email = "joe@example.com"
    @user_joe.email = email
    @user_joe.save!

    rule = create(
      :automation_rule, name: "Finding users by excluding email",
      organization: @rule.organization)
    condition = create(
      :outbound_condition, conditionable: rule, field: "email", verb: "is_not",
      value: email + ".not")

    assert condition.match_user?(@user_joe)
  end

  test "matching_users - email contains" do
    email = "joe@example.com"
    @user_joe.email = email
    @user_joe.save!

    rule = create(:automation_rule, name: "Finding users with email", organization: @rule.organization)
    condition = create(:outbound_condition, conditionable: rule, field: "email", verb: "contains", value: email)

    assert condition.match_user?(@user_joe)
  end

  test "matching_users - less-than days since last login" do
    @user_joe.last_sign_in_at = 1.days.ago.beginning_of_day
    @user_matt.last_sign_in_at = 2.days.ago.beginning_of_day
    @user_ken.last_sign_in_at = 3.days.ago.beginning_of_day

    @user_joe.save!
    @user_matt.save!
    @user_ken.save!

    rule = create(
      :automation_rule, name: "Finding users based on last sign in",
      organization: @organization)
    condition = create(
      :outbound_condition,
      conditionable: rule,
      field: "last_sign_in_at",
      verb: "less_than",
      value: "1")

    assert_equal 1, condition.matching_users.count
    assert condition.match_user?(@user_joe)
  end

  test "matching_users - greater-than days since last login" do
    @user_joe.last_sign_in_at = 10.days.ago.beginning_of_day
    @user_matt.last_sign_in_at = 2.days.ago.beginning_of_day
    @user_ken.last_sign_in_at = 30.days.ago.beginning_of_day

    @user_joe.save!
    @user_matt.save!
    @user_ken.save!

    rule = create(
      :automation_rule, name: "Finding users based on last sign in",
      organization: @organization)
    condition = create(
      :outbound_condition,
      conditionable: rule,
      field: "last_sign_in_at",
      verb: "greater_than",
      value: "7")

    assert_equal 2, condition.matching_users.count
    assert condition.match_user?(@user_joe)
  end

  test "matching_users - equal days since last login" do
    @user_joe.update(last_sign_in_at: 3.days.ago.beginning_of_day)
    @user_ken.update(last_sign_in_at: 2.days.ago.beginning_of_day)
    @user_matt.update(last_sign_in_at: 5.days.ago.beginning_of_day)

    rule = create(
      :automation_rule, name: "Finding users based on last sign in",
      organization: @organization)
    condition = create(
      :outbound_condition,
      conditionable: rule,
      field: "last_sign_in_at",
      verb: "is",
      value: "3")

    assert_equal 1, condition.matching_users.count
    assert condition.match_user?(@user_joe)
  end

  test "matching_users - equal days since sign up" do
    @user_joe.update(created_at: 3.days.ago.beginning_of_day)
    @user_ken.update(created_at: 3.days.ago.beginning_of_day)
    @user_matt.update(created_at: 7.days.ago.beginning_of_day)

    rule = create(
      :automation_rule, name: "Finding users based on when they signed up",
      organization: @organization)
    condition = create(
      :outbound_condition,
      conditionable: rule,
      field: "created_at",
      verb: "is",
      value: "3")

    assert_equal 2, condition.matching_users.count
    assert condition.match_user?(@user_joe)
    assert condition.match_user?(@user_ken)
  end

  test "matching_users - less than days since sign up" do
    @user_joe.update(created_at: 4.days.ago.beginning_of_day)
    @user_ken.update(created_at: 30.days.ago.beginning_of_day)
    @user_matt.update(created_at: 6.days.ago.beginning_of_day)

    rule = create(
      :automation_rule, name: "Finding users based on when they signed up",
      organization: @organization)
    condition = create(
      :outbound_condition,
      conditionable: rule,
      field: "created_at",
      verb: "less_than",
      value: "6")

    assert_equal 2, condition.matching_users.count
    assert condition.match_user?(@user_joe)
    assert condition.match_user?(@user_matt)
  end

  test "matching_users - greater than days since sign up" do
    @user_joe.update(created_at: 4.days.ago.beginning_of_day)
    @user_ken.update(created_at: 3.days.ago.beginning_of_day)
    @user_matt.update(created_at: 6.days.ago.beginning_of_day)

    rule = create(
      :automation_rule, name: "Finding users based on when they signed up",
      organization: @organization)
    condition = create(
      :outbound_condition,
      conditionable: rule,
      field: "created_at",
      verb: "greater_than",
      value: "4")

    assert_equal 1, condition.matching_users.count
    assert condition.match_user?(@user_matt)
  end
end
