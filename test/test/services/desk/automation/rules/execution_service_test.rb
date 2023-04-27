# frozen_string_literal: true

require "test_helper"
class Desk::Automation::Rules::ExecutionServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @user = create(:user_with_agent_role, organization: @organization)
    @ticket = create(
      :ticket, organization: @organization,
      subject: "I have received my refund, done with the ticket, can be closed")
    User.current = @user
  end

  def test_that_rule_is_executed
    rule = create :automation_rule, name: "Close ticket when subject contains done", organization: @organization
    group = create :automation_condition_group, rule: rule
    create :desk_core_condition, conditionable: group, join_type: "and_operator", field: "subject", verb: "contains", value: "done"
    create :automation_action, rule: rule, name: "change_ticket_status", status: "closed"

    service = Desk::Automation::Rules::ExecutionService.new(rule)
    assert_equal "open", @ticket.status

    assert_difference "Desk::Automation::ExecutionLogEntry.count" do
      service.process
    end

    assert @ticket.reload.status_closed?
    assert_equal :ok, service.status
    assert_equal "Rule has been successfully applied.", service.response[:notice]
  end

  def test_that_deep_dependent_rules_are_executed
    Sidekiq::Testing.inline!

    ethan = create :user, organization: @organization, first_name: "Ethan", last_name: "Hunt"

    rule_1 = create :automation_rule,
      name: "Assign ticket to Ethan Hunt",
      organization: @organization

    group_1 = create :automation_condition_group, rule: rule_1
    create :desk_core_condition, conditionable: group_1, field: "subject", verb: "contains", value: "done"
    create :automation_action, rule: rule_1, name: "assign_agent", actionable: ethan, status: nil

    # Dependent on rule_1
    rule_2 = create :automation_rule, :on_ticket_update,
      name: "Mark ETHAN's tickets as High priority",
      organization: @organization
    condition_group_2 = create :automation_condition_group, :match_all, rule: rule_2
    create :automation_condition, conditionable: condition_group_2, field: "agent_id", verb: "is", value: ethan.id
    create :automation_action, rule: rule_2, name: "add_note", body: "This is a note", status: nil

    # Dependent on rule_2
    tag = create :ticket_tag, organization: @organization
    rule_3 = create :automation_rule, :on_note_added,
      name: "Add tag to high priority tickets",
      organization: @organization
    condition_group_3 = create :automation_condition_group, :match_all, rule: rule_3
    create :automation_condition, conditionable: condition_group_3, field: "agent_id", verb: "is", value: ethan.id
    create :automation_action, rule: rule_3, name: "set_tags", tag_ids: [tag.id], status: nil

    # This shall not pass as rule 2 emmits on_note_added and not on_reply_added event
    rule_3 = create :automation_rule, :on_reply_added,
      name: "Add more tags to high priority tickets",
      organization: @organization
    condition_group_3 = create :automation_condition_group, :match_all, rule: rule_3
    create :automation_condition, conditionable: condition_group_3, field: "agent_id", verb: "is", value: ethan.id
    create :automation_action, rule: rule_3, name: "set_tags", tag_ids: [tag.id], status: nil

    assert_nil @ticket.agent_id
    assert_equal "low", @ticket.priority

    assert_difference "Desk::Automation::ExecutionLogEntry.count", 3 do
      Desk::Automation::Rules::ExecutionService.new(rule_1).process
    end

    @ticket.reload
    assert_equal ethan.id, @ticket.agent.id
    assert_equal tag.name, @ticket.tags.first.name
  end
end
