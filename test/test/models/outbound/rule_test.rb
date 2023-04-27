# frozen_string_literal: true

require "test_helper"

class Outbound::RuleTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @user_joe = create :user, email: "joe@example.com", organization: @organization
    @user_ken = create :user, email: "ken@example.com", organization: @organization
    @user_matt = create :user, email: "matt@example.com", organization: @organization
  end

  test "matching_users - single condition" do
    rule = create(:outbound_message_rule, organization: @organization)
    condition_subject_contains_joe = create(:outbound_condition_email_contains_joe, conditionable: rule)

    rule.reload
    assert_includes rule.matching_users, @user_joe
  end

  test "matching_users - C1 OR C2" do
    rule = create(:outbound_message_rule, organization: @organization)

    @user_ken.update(last_sign_in_at: DateTime.now - 2.days)
    c1 = create(:outbound_condition_email_contains_joe, conditionable: rule, sequence: 1)
    c2 = create(
      :outbound_condition_last_sign_in_is_less_than_3days, conditionable: rule, sequence: 2,
      join_type: "or_operator")

    rule.reload

    assert_equal 2, rule.matching_users.count
    assert_includes rule.matching_users, @user_ken
    assert_includes rule.matching_users, @user_joe
  end

  test "matching_users - C1 AND C2" do
    @user_joe.update(created_at: 7.days.ago.beginning_of_day)

    rule = create(:outbound_message_rule, organization: @organization)

    c1 = create(:outbound_condition_email_contains_joe, conditionable: rule, sequence: 1)
    c2 = create(
      :outbound_condition_since_sign_up_is_greater_than_4days, conditionable: rule, sequence: 2,
      join_type: "and_operator")

    rule.reload

    assert_equal 1, rule.matching_users.count
  end

  def test_that_user_is_matched_with_rule
    rule = create(:outbound_message_rule, organization: @organization)
    create(:outbound_condition, conditionable: rule, field: "email", verb: "contains", value: "joe")

    assert rule.match_user?(@user_joe)
  end

  test "matching_users - last sign in single condition" do
    @user_joe.update(last_sign_in_at: 1.days.ago.beginning_of_day)

    rule = create(:outbound_message_rule, organization: @organization)
    condition_last_sign_in_is_less_than_3days = create(
      :outbound_condition_last_sign_in_is_less_than_3days,
      conditionable: rule)

    rule.reload
    assert_includes rule.matching_users, @user_joe
  end

  test "matching_users - since sign up single condition" do
    @user_joe.update(created_at: 5.days.ago.beginning_of_day)

    rule = create(:outbound_message_rule, organization: @organization)
    condition_since_sign_up_is_greater_than_4days = create(
      :outbound_condition_since_sign_up_is_greater_than_4days,
      conditionable: rule)

    rule.reload
    assert_includes rule.matching_users, @user_joe
  end
end
