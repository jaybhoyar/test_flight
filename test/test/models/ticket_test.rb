# frozen_string_literal: true

require "test_helper"

class TicketTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @agent_role = create :organization_role_agent, organization: @organization
    @ticket = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization, role: nil),
      agent: create(:user, organization: @organization, role: @agent_role),
      number: 2,
      category: "Questions"

    @ethan = create(:user, organization: @organization)
    User.current = @ethan

    @organization = create(:organization)
    @refund_ticket = create(:ticket, subject: "Please Refund my money!", organization: @organization)
    @urgent_ticket = create(:ticket, subject: "[Urgent] Cannot see any incoming tickets", organization: @organization)
    @combo_ticket = create(:ticket, subject: "Refund my money - Urgent", organization: @organization)
    @subject = "Please create a ticket for me, Please!"
    @content = "This is the content"
  end

  test "valid ticket" do
    assert @ticket.valid?
  end

  test "default priority" do
    assert_equal @ticket.priority, "low"
  end

  def test_that_ticket_cannot_be_created_as_trashed
    ticket = build :ticket, status: "trash"
    assert_not ticket.valid?
  end

  def test_assign_agent
    agent = create :user, organization: @organization
    ticket = create :ticket, organization: @organization
    assert_difference "Activity.count", 1 do
      ticket.assign_agent(agent.id)
    end
    ticket.reload
    assert_equal agent.id, ticket.agent_id
    assert_not_nil ticket.assigned_at
    assert_not_nil ticket.last_assigned_at
    assert_equal ticket.assigned_at, ticket.last_assigned_at

    agent_2 = create :user, organization: @organization
    assert_difference "Activity.count", 1 do
      ticket.assign_agent(agent_2.id)
    end
    ticket.reload
    assert_equal agent_2.id, ticket.agent_id
    assert_not_equal ticket.assigned_at, ticket.last_assigned_at
  end

  test "redact subject when automatic redaction is enabled" do
    create(:setting, automatic_redaction: true, organization: @organization)
    cc_number = "4111 1111 1111 1111"
    text = "My card number is #{cc_number}, please fix the issue."
    ticket = create(:ticket, subject: text, organization: @organization)
    assert_includes ticket.subject, cc_number.slice(0...6)
    assert_not_includes ticket.subject, cc_number
  end

  test "do not redact subject when automatic redaction is disabled" do
    create(:setting, organization: @organization, automatic_redaction: false)
    cc_number = "4111 1111 1111 1111"
    text = "My card number is #{cc_number}, please fix the issue."
    ticket = create(:ticket, subject: text, organization: @organization)
    assert_includes ticket.subject, cc_number
  end

  test "logs activity for ticket creation" do
    assert_difference "Activity.count", 1 do
      customer = create(:user, organization: @organization)
      ticket = create :ticket,
        subject: "Unable to login",
        requester: customer,
        organization: @organization

      assert_equal 1, ticket.activities.count
      first_activity = ticket.activities.first

      assert_equal "activity.ticket.create", first_activity.key
      assert_equal customer.name, first_activity.owner.name
      assert_equal I18n.t("activity.ticket.create"), first_activity.action
    end
  end

  test "logs activity for ticket status change" do
    assert_difference "Activity.count", 2 do
      ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      assert ticket.status == "open"

      ticket.update(status: Ticket::DEFAULT_STATUSES[:resolved])
      latest_activity = ticket.activities.order(:created_at).last
      assert_equal User.current.name, latest_activity.owner.name
      assert_equal "activity.ticket.update.status", latest_activity.key
    end
  end

  test "logs activity for ticket agent change " do
    assert_difference "Activity.count", 2 do
      ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      hunt = create(:user, organization: @organization)

      old_value = ticket.agent.name
      ticket.update(agent_id: hunt.id)
      latest_activity = ticket.activities.order(:created_at).last
      assert_equal "activity.ticket.update.agent_id.reassigned", latest_activity.key
      assert_equal User.current.name, latest_activity.owner.name
      assert_equal I18n.t(
        "activity.ticket.update.agent_id.reassigned",
        current_user_name: User.current.name, old_value: old_value.titleize, new_value: hunt.name.titleize),
        latest_activity.action
    end
  end

  test "logs activity for assigning agent to ticket first time " do
    assert_difference "Activity.count", 2 do
      ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      hunt = create(:user, organization: @organization)

      ticket.update(agent_id: hunt.id)
      latest_activity = ticket.activities.order(:created_at).last
      assert_equal "activity.ticket.update.agent_id.assigned", latest_activity.key
      assert_equal User.current.name, latest_activity.owner.name
      assert_equal I18n.t(
        "activity.ticket.update.agent_id.assigned",
        current_user_name: User.current.name, old_value: "", new_value: hunt.name.titleize),
        latest_activity.action
    end
  end

  test "logs activity for ticket priority change " do
    assert_difference "Activity.count", 2 do
      ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      ticket.update(priority: "medium")
      latest_activity = ticket.activities.order(:created_at).last
      assert_equal User.current.name, latest_activity.owner.name
      assert_equal "activity.ticket.update.priority", latest_activity.key
    end
  end

  test "logs activity for ticket category change " do
    assert_difference "Activity.count", 2 do
      ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      ticket.update(category: "Questions")
      latest_activity = ticket.activities.order(:created_at).last
      assert_equal User.current.name, latest_activity.owner.name
      assert_equal "activity.ticket.update.category", latest_activity.key
    end
  end

  test "logs activity for ticket subject change " do
    assert_difference "Activity.count", 2 do
      ticket = create :ticket,
        organization: @organization,
        requester: create(:user, organization: @organization),
        agent: create(:user, organization: @organization),
        priority: 2,
        category: "None"

      ticket.update(subject: "Incorrect invoice generated")
      latest_activity = ticket.activities.order(:created_at).last
      assert_equal User.current.name, latest_activity.owner.name
      assert_equal "activity.ticket.update.subject", latest_activity.key
    end
  end

  test "matching_rules - single matching rule" do
    rule = create :automation_rule, :on_ticket_create, organization: @organization

    group = create :automation_condition_group, rule: rule
    c1 = create(:automation_condition_subject_contains_refund, conditionable: group, sequence: 1)

    assert_equal [rule], @refund_ticket.matching_rules("created")
  end

  test "matching_rules - multiple matching rules" do
    rule1 = create :automation_rule, :on_ticket_create, organization: @organization
    group_1 = create :automation_condition_group, rule: rule1
    c1 = create :automation_condition_subject_contains_refund, conditionable: group_1, sequence: 1

    rule2 = create :automation_rule, :on_ticket_create, organization: @organization, name: "Set urgency"
    group_2 = create :automation_condition_group, rule: rule2
    c2 = create :automation_condition_subject_contains_urgent, conditionable: group_2, sequence: 1

    assert_equal 2, @combo_ticket.matching_rules("created").count
    assert_includes @combo_ticket.matching_rules("created"), rule1
    assert_includes @combo_ticket.matching_rules("created"), rule2
  end

  test "that ticket matches on rule for which it has already been executed" do
    refund_ticket2 = create(:ticket, subject: "When can I expect my refund?", organization: @organization)
    rule = create :automation_rule, :on_ticket_create, organization: @organization
    group = create :automation_condition_group, rule: rule
    c1 = create :automation_condition_subject_contains_refund, conditionable: group

    create :execution_log_entry, rule: rule, ticket: @refund_ticket

    assert_includes @refund_ticket.matching_rules("created"), rule
    assert_equal [rule], refund_ticket2.matching_rules("created")
  end

  test "that ticket does not match on time based rule for which it has already been executed" do
    refund_ticket2 = create(:ticket, subject: "When can I expect my refund?", organization: @organization)
    rule = create :automation_rule, :time_based, organization: @organization
    group = create :automation_condition_group, rule: rule
    c1 = create :automation_condition_subject_contains_refund, conditionable: group

    create :execution_log_entry, rule: rule, ticket: @refund_ticket

    assert_not_includes rule.matching_tickets, @refund_ticket
  end

  test "that ticket matches on rule for which it has already been executed less than 100 times" do
    refund_ticket2 = create(:ticket, subject: "When can I expect my refund?", organization: @organization)
    rule = create(:automation_rule, :on_ticket_create, organization: @organization)
    group = create :automation_condition_group, rule: rule
    c1 = create :automation_condition_subject_contains_refund, conditionable: group
    create :execution_log_entry, rule: rule, ticket: @refund_ticket

    assert_not_empty @refund_ticket.matching_rules("created")
    assert_equal [rule], refund_ticket2.matching_rules("created")
  end

  def test_update_ticket_last_agent_reply_at_success
    comment = create(:comment, ticket: @ticket)

    assert_equal comment.created_at.to_i, @ticket.last_customer_reply_at.to_i
  end

  def test_update_ticket_last_customer_reply_at_success
    comment = create(:comment, ticket: @ticket)

    assert_equal comment.created_at.to_i, @ticket.last_customer_reply_at.to_i
  end

  def test_that_activity_is_created_when_tags_are_added
    tag_1 = create :ticket_tag, name: "Urgent", organization: @organization
    tag_2 = create :ticket_tag, name: "Primary", organization: @organization

    assert_difference "@ticket.tags.count", 2 do
      assert_difference "@ticket.activities.count" do
        @ticket.update_tags([tag_1, tag_2])
      end
    end
  end

  def test_that_activity_is_created_when_tags_are_removed
    tag_1 = create :ticket_tag, name: "Urgent", organization: @organization

    @ticket.update_tags([tag_1])

    assert_difference "@ticket.tags.count", -1 do
      assert_difference "@ticket.activities.count" do
        @ticket.update_tags([])
      end
    end
  end

  def test_that_activity_is_created_when_tags_are_updated
    tag_1 = create :ticket_tag, name: "Urgent", organization: @organization
    tag_2 = create :ticket_tag, name: "Primary", organization: @organization

    @ticket.update_tags([tag_1])

    assert_no_difference "@ticket.tags.count" do
      assert_difference "@ticket.activities.count" do
        @ticket.update_tags([tag_2])
      end
    end
  end

  def test_spammed
    refute @ticket.spammed?
    @ticket.update(status: "spam")

    assert @ticket.spammed?
  end

  def test_trashed
    refute @ticket.trashed?
    @ticket.update(status: "trash")

    assert @ticket.trashed?
  end

  def test_that_followers_are_created_on_ticket_create
    jason = create :user, organization: @organization

    # No submitter, No Agent
    assert_difference "::Desk::Ticket::Follower.count", 1 do
      create :ticket, organization: @organization
    end

    # No submitter, No Agent
    assert_difference "::Desk::Ticket::Follower.count", 1 do
      create :ticket, :with_desc, organization: @organization
    end

    # No Agent
    assert_difference "::Desk::Ticket::Follower.count", 2 do
      create :ticket, organization: @organization, submitter: jason
    end

    # No submitter
    assert_difference "::Desk::Ticket::Follower.count", 2 do
      create :ticket, organization: @organization, agent: @ethan
    end

    assert_difference "::Desk::Ticket::Follower.count", 3 do
      create :ticket, organization: @organization, agent: @ethan, submitter: jason
    end
  end

  def test_that_repeated_followers_are_not_created
    assert_difference "::Desk::Ticket::Follower.count", 2 do
      create :ticket, organization: @organization, agent: @ethan, submitter: @ethan
    end
  end

  def test_that_followers_are_created_on_ticket_update
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil

    assert_difference "::Desk::Ticket::Follower.count", 1 do
      ticket.update(agent: @ethan)
    end
  end

  def test_that_existing_subscriber_is_updated_as_assigned_on_ticket_update
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    follower = create :desk_ticket_follower, ticket: ticket, user: @ethan, kind: :subscriber

    assert follower.subscriber?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      ticket.update(agent: @ethan)
    end

    assert follower.reload.assigned?
  end

  def test_that_existing_mentioned_is_updated_as_assigned_on_ticket_update
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    follower = create :desk_ticket_follower, ticket: ticket, user: @ethan, kind: :mentioned

    assert follower.mentioned?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      ticket.update(agent: @ethan)
    end

    assert follower.reload.assigned?
  end

  def test_that_existing_commented_is_updated_as_assigned_on_ticket_update
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    follower = create :desk_ticket_follower, ticket: ticket, user: @ethan, kind: :commented

    assert follower.commented?
    assert_no_difference "::Desk::Ticket::Follower.count" do
      ticket.update(agent: @ethan)
    end

    assert follower.reload.assigned?
  end

  def test_calculate_resolution_time
    travel_to 3.5.hours.ago
    ticket = create :ticket, organization: @organization, agent: nil, submitter: nil
    travel_back

    travel_to 1.hour.ago
    ticket.update! status: "resolved"
    travel_back

    assert_equal 2.5, ticket.send(:calculate_resolution_time)
  end

  def test_task_activities_has_only_task_related_activities
    assert_difference "Activity.count", 4 do
      task = @ticket.tasks.create(name: "Call customer")
      task.update!(name: "Call customer on skype.", status: "wont_do")
      task.destroy

      assert_equal 4, @ticket.task_activities.count
      assert_equal 1, @ticket.non_task_activities.count
    end
  end

  def test_uniqueness_of_parent_task
    task = @ticket.tasks.create(name: "Refund Money", info: "refund money to customer")

    sub_ticket1 = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization, role: nil),
      agent: create(:user, organization: @organization, role: @agent_role),
      number: 3,
      category: "Questions",
      parent_task_id: task.id

    sub_ticket2 = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization, role: nil),
      agent: create(:user, organization: @organization, role: @agent_role),
      number: 4,
      category: "Questions"

    sub_ticket2.parent_task_id = task.id

    assert_not sub_ticket2.valid?
  end

  def test_returned_parent_ticket_is_correct
    task = @ticket.tasks.create(name: "Refund Money", info: "refund money to customer")

    sub_ticket1 = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization, role: nil),
      agent: create(:user, organization: @organization, role: @agent_role),
      number: 3,
      category: "Questions",
      parent_task_id: task.id

    assert_equal @ticket, sub_ticket1.parent_ticket
    assert_nil @ticket.parent_ticket
  end

  def test_update_last_agent_reply_when_commenter_is_not_customer
    ticket = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization, role: @agent_role)

    agent = create(:user, organization: @organization, role: @agent_role)
    comment = create(:comment, ticket:, author: agent)

    assert_equal comment.created_at.to_i, ticket.last_agent_reply_at.to_i
    assert_nil ticket.last_customer_reply_at
  end

  def test_update_last_agent_reply_when_commenter_is_customer
    ticket = create :ticket,
      organization: @organization,
      requester: create(:user, organization: @organization, role: nil)

    customer = create(:user, organization: @organization, role: nil)
    comment = create(:comment, ticket:, author: customer)

    assert_equal comment.created_at.to_i, ticket.last_customer_reply_at.to_i
    assert_nil ticket.last_agent_reply_at
  end

  def test_ticket_can_be_closed_without_filling_required_ticket_fields_with_skip
    create :ticket_field, is_required_for_agent_when_closing_ticket: true, organization: @organization
    ticket = create :ticket, organization: @organization

    ticket.skip_status_validation = true
    assert ticket.update(status: "closed")
  end

  def test_ticket_cannot_be_closed_without_filling_required_ticket_fields
    create :ticket_field, is_required_for_agent_when_closing_ticket: true, organization: @organization
    ticket = create :ticket, organization: @organization

    assert_not ticket.update(status: "closed")
  end

  def test_ticket_can_be_closed_without_filling_not_required_ticket_fields
    create :ticket_field, is_required_for_agent_when_closing_ticket: true, state: :inactive, organization: @organization
    ticket = create :ticket, organization: @organization

    assert ticket.update(status: "closed")
  end

  def test_ticket_cannot_be_closed_without_filling_category
    category_field = create :ticket_field, :system_category, organization: @organization
    category_field.update(is_required_for_agent_when_closing_ticket: true)

    ticket = create :ticket, organization: @organization, category: "None"

    assert_not ticket.update(status: "closed")
  end

  def test_ticket_cannot_be_closed_without_filling_group
    group_field = create :ticket_field, :system_group, organization: @organization
    group_field.update(is_required_for_agent_when_closing_ticket: true)

    ticket = create :ticket, organization: @organization, group_id: nil

    assert_not ticket.update(status: "closed")
  end

  def test_ticket_cannot_be_closed_without_filling_agent
    agent_field = create :ticket_field, :system_agent, organization: @organization
    agent_field.update(is_required_for_agent_when_closing_ticket: true)

    ticket = create :ticket, organization: @organization, agent: nil

    assert_not ticket.update(status: "closed")
  end

  def test_that_ticket_cannot_be_created_when_customer_is_deactivated
    requester = create(:user, organization: @organization, role: nil)
    requester.deactivate!

    ticket = build(:ticket, requester:, submitter: requester)

    assert_not ticket.valid?
    assert_equal "Blocked customers cannot create tickets.", ticket.errors.full_messages[0]
  end

  def test_that_agent_cannot_create_ticket_when_customer_is_deactivated
    requester = create(:user, organization: @organization, role: nil)
    requester.deactivate!

    submitter = create(:user, :agent, organization: @organization)

    ticket = build(:ticket, requester:, submitter:)

    assert_not ticket.valid?
    assert_equal "Tickets cannot be created for blocked customers.", ticket.errors.full_messages[0]
  end
end
