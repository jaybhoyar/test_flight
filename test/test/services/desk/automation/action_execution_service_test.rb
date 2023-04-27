# frozen_string_literal: true

require "test_helper"
class Desk::Automation::ActionExecutionServiceTest < ActiveSupport::TestCase
  def setup
    stub_request(:any, /fonts.googleapis.com/)
  end

  def test_activity_is_created_with_rule_as_owner
    User.current = nil
    agent = create :user
    ticket = create :ticket, :with_desc
    rule = create :automation_rule, organization: ticket.organization
    action = create :automation_action, name: "assign_agent", actionable: agent, rule: rule

    assert_difference "ticket.activities.count" do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end

    activity = ticket.activities.where(key: "system.activity.ticket.update.agent_id.assigned").first
    assert_equal rule.id, activity.owner_id
  end

  def parse_email_body(html)
    Nokogiri::HTML(html).css("body").inner_html.strip
  end

  def test_assign_agent_action
    agent = create :user
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "assign_agent", actionable: agent

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal ticket.agent, action.actionable
  end

  def test_change_ticket_status_action
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "change_ticket_status", status: "closed"

    assert_not_equal ticket.status, action.status

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal ticket.status, action.status
  end

  def test_change_ticket_priority_action
    ticket = create :ticket, :with_desc, priority: 0
    action = create :automation_action, name: "change_ticket_priority", value: "urgent"

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert ticket.urgent?
  end

  def assign_group_action
    group = create :group
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "assign_group", actionable: group

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal group.id, ticket.reload.group_id
  end

  def test_set_tags_action
    tag = create :ticket_tag
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "set_tags", tag_ids: [tag.id]

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal 1, action.tags.count
    assert_includes ticket.tags, action.tags.first
  end

  def test_that_set_tags_replaces_existing_tags
    tag = create :ticket_tag
    tag_2 = create :ticket_tag
    ticket = create :ticket, :with_desc
    ticket.update_tags([tag])

    action = create :automation_action, name: "set_tags", tag_ids: [tag_2.id]

    assert_includes ticket.reload.tags, tag
    Desk::Automation::ActionExecutionService.new(action, ticket).run
    assert_includes ticket.reload.tags, tag_2
  end

  def test_add_tags_action
    tag = create :ticket_tag
    tag_2 = create :ticket_tag
    ticket = create :ticket, :with_desc
    ticket.update_tags([tag])
    action = create :automation_action, name: "add_tags", tag_ids: [tag_2.id]

    Desk::Automation::ActionExecutionService.new(action, ticket).run
    assert_includes ticket.tags, tag_2
  end

  def test_add_tags_action_with_existing_tags
    tag = create :ticket_tag
    ticket = create :ticket, :with_desc
    ticket.update_tags([tag])
    action = create :automation_action, name: "add_tags", tag_ids: [tag.id]

    Desk::Automation::ActionExecutionService.new(action, ticket).run
    assert_equal 1, ticket.tags.count
  end

  def test_remove_tags_action
    tag = create :ticket_tag
    tag_2 = create :ticket_tag
    ticket = create :ticket, :with_desc
    ticket.update_tags([tag, tag_2])
    action = create :automation_action, name: "remove_tags", tag_ids: [tag.id]

    Desk::Automation::ActionExecutionService.new(action, ticket).run
    assert_not_includes ticket.tags, tag
  end

  def test_remove_tags_action_with_existing_tags
    tag = create :ticket_tag
    ticket = create :ticket, :with_desc
    ticket.update_tags([tag])
    action = create :automation_action, name: "remove_tags", tag_ids: [tag.id]

    Desk::Automation::ActionExecutionService.new(action, ticket).run
    assert_empty ticket.tags
  end

  def test_email_to_requester
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "email_to_requester",
      subject: "Our team is already working on the issue.",
      body: "We will fix this ASAP."

    assert_emails 1 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
  end

  def test_email_to_requester_with_variables
    organization = create :organization
    tag_1 = create :ticket_tag, organization: organization, name: "Charging"
    tag_2 = create :ticket_tag, organization: organization, name: "Educational"

    ticket = create :ticket, :with_desc, organization: organization
    ticket.update_tags([tag_1, tag_2])

    action = create :automation_action, name: "email_to_requester",
      subject: "We are working on it at {{ticket.organization.name}} headquarters.",
      body: test_body

    assert_emails 1 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
    email = ActionMailer::Base.deliveries.last
    body = parse_email_body(email.html_part.body.raw_source)

    assert_includes body, valid_body(ticket).strip
    assert_includes body, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_email_to_assigned_agent
    agent = create :user
    ticket = create :ticket, :with_desc, agent: agent, organization: agent.organization
    action = create :automation_action, name: "email_to_assigned_agent",
      subject: "Our team is already working on the issue.",
      body: "We will fix this ASAP."

    assert_emails 1 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
  end

  def test_email_to_assigned_agent_doesnt_fail_when_ticket_is_unassigned
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "email_to_assigned_agent",
      subject: "Our team is already working on the issue.",
      body: "We will fix this ASAP."

    assert_emails 0 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
  end

  def test_email_to_agent
    agent = create :user
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "email_to_agent", actionable: agent,
      subject: "Our team is already working on the issue.",
      body: "We will fix this ASAP."

    assert_emails 1 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
  end

  def test_email_to_all_agents
    organization = create :organization

    permission_1 = Permission.find_or_create_by(name: "desk.view_tickets", category: "Desk")
    permission_2 = Permission.find_or_create_by(name: "desk.reply_add_note_to_tickets", category: "Desk")
    permission_3 = Permission.find_or_create_by(name: "desk.manage_tickets", category: "Desk")

    agent_role = create :organization_role,
      name: "Agent",
      permissions: [permission_1, permission_2, permission_3],
      organization: organization

    create :user, organization: organization, role: agent_role
    create :user, organization: organization, role: agent_role
    create :user, organization: organization

    ticket = create :ticket, :with_desc, organization: organization, group: nil
    action = create :automation_action, name: "email_to_all_agents",
      subject: "Our team is already working on the issue.",
      body: "We will fix this ASAP."

    assert_emails 2 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
  end

  def test_email_to
    Sidekiq::Testing.inline!

    user = create :user
    ticket = create :ticket, :with_desc, requester: user, organization: user.organization
    rule = create :automation_rule, organization: user.organization
    action = create :automation_action, name: "email_to", rule: rule,
      value: "payments@example.com,refunds@example.com,finance.support@example.com",
      subject: "Our team is already working on the issue.",
      body: '<div>We got you covered for #{{ticket.number}}</div>'

    assert_emails 3 do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end

    email = ActionMailer::Base.deliveries.last
    assert_includes email.to, "finance.support@example.com"
    assert_includes email.subject, "Re: #{ticket.subject}"

    body = parse_email_body(email.html_part.body.raw_source)
    assert_includes body, "<div>We got you covered for ##{ticket.number}</div>"
    assert_includes body, "TICKETS EMAIL FOOTER CONTENT"
  end

  def test_add_note
    user = create :user
    ticket = create :ticket, :with_desc, requester: user, organization: user.organization
    rule = create :automation_rule, organization: user.organization
    action = create :automation_action, name: "add_note", rule: rule,
      body: '<div>We got you covered for #{{ticket.number}}</div>'

    assert_difference "Comment.count" do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end

    assert_equal 2, ticket.comments.count
    comment = ticket.comments.note.first
    assert_equal "<div>We got you covered for ##{ticket.number}</div>", comment.info.body.to_html
  end

  def test_assign_agent_round_robin
    organization = create :organization
    agent_role = create :organization_role_agent, organization: organization
    user_1 = create :user, organization: organization, role: agent_role
    user_2 = create :user, organization: organization, role: agent_role
    user_3 = create :user, organization: organization, role: agent_role

    ticket = create :ticket, :with_desc, requester: user_1, organization: organization, group: nil
    rule = create :automation_rule, organization: organization
    action = create :automation_action, name: "assign_agent_round_robin", rule: rule

    Desk::Automation::ActionExecutionService.new(action, ticket).run
    assert_equal user_1.id, ticket.reload.agent_id

    ticket_2 = create :ticket, requester: user_1, organization: organization, group: nil
    Desk::Automation::ActionExecutionService.new(action, ticket_2).run
    assert_equal user_2.id, ticket_2.reload.agent_id

    ticket_3 = create :ticket, requester: user_1, organization: organization, group: nil
    Desk::Automation::ActionExecutionService.new(action, ticket_3).run
    assert_equal user_3.id, ticket_3.reload.agent_id

    ticket_4 = create :ticket, requester: user_1, organization: organization, group: nil
    Desk::Automation::ActionExecutionService.new(action, ticket_4).run
    assert_equal user_1.id, ticket_4.reload.agent_id
  end

  def test_assign_to_first_responder
    organization = create :organization
    agent_role = create :organization_role_agent, organization: organization
    user = create :user, organization: organization, role: agent_role
    user_2 = create :user, organization: organization, role: agent_role
    ticket = create :ticket, :with_desc, requester: user, organization: organization
    create :comment, ticket: ticket, author: user, created_at: Time.current - 5.minutes
    create :comment, ticket: ticket, author: user_2, created_at: Time.current

    rule = create :automation_rule, organization: user.organization
    action = create :automation_action, name: "assign_to_first_responder", rule: rule

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal user.id, ticket.reload.agent_id
  end

  def test_assign_to_first_responder_doesnt_fail_when_there_is_no_comment
    organization = create :organization
    agent_role = create :organization_role_agent, organization: organization
    user = create :user, role: agent_role, organization: organization
    ticket = create :ticket, :with_desc, requester: user, organization: organization
    rule = create :automation_rule, organization: user.organization
    action = create :automation_action, name: "assign_to_first_responder", rule: rule

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_nil ticket.reload.agent_id
  end

  def test_assign_to_last_responder
    organization = create :organization
    agent_role = create :organization_role_agent, organization: organization
    user = create :user, role: agent_role, organization: organization
    user_2 = create :user, organization: organization, role: agent_role
    ticket = create :ticket, :with_desc, requester: user, organization: organization
    create :comment, ticket: ticket, author: user, created_at: Time.current - 5.minutes
    create :comment, ticket: ticket, author: user_2, created_at: Time.current

    rule = create :automation_rule, organization: user.organization
    action = create :automation_action, name: "assign_to_last_responder", rule: rule

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal user_2.id, ticket.reload.agent_id
  end

  def test_assign_to_last_responder_doesnt_fail_when_there_is_no_comment
    organization = create :organization
    agent_role = create :organization_role_agent, organization: organization
    user = create :user, role: agent_role, organization: organization
    ticket = create :ticket, :with_desc, requester: user, organization: organization
    rule = create :automation_rule, organization: user.organization
    action = create :automation_action, name: "assign_to_last_responder", rule: rule

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_nil ticket.reload.agent_id
  end

  def test_remove_assigned_agent_action
    agent = create :user, available_for_desk: false
    ticket = create :ticket, :with_desc, agent: agent, status: "open"

    action = create :automation_action, name: "remove_assigned_agent"

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_nil ticket.agent
  end

  def test_add_task_list_action
    task_list = create :desk_task_list
    ticket = create :ticket, :with_desc
    action = create :automation_action, name: "add_task_list", actionable: task_list

    Desk::Automation::ActionExecutionService.new(action, ticket).run

    assert_equal task_list.items.count, ticket.tasks.count
  end

  def test_message_to_slack_success
    Slack::Web::Client.any_instance.stubs(:chat_postMessage).returns(true)

    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .with(
        body: { "channel" => "general", "text" => "Test message to slack", "token" => nil },
        headers: {
          "Accept" => "application/json; charset=utf-8",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "Slack Ruby Client/0.14.6"
        })
      .to_return(status: 200, body: "", headers: {})

    ticket = create :ticket, :with_desc
    create :slack_team, organization: ticket.organization
    rule = create :automation_rule, organization: ticket.organization
    action = create :automation_action, rule: rule, name: "message_to_slack", value: "general", body: "Test message to slack"

    assert_no_difference "rule.activities.count" do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end

    assert rule.active
  end

  def test_message_to_slack_action_deactivates_rule_without_slack_team
    ticket = create :ticket, :with_desc
    rule = create :automation_rule, organization: ticket.organization
    action = create :automation_action, rule: rule, name: "message_to_slack", value: "general", body: "Test message to slack"

    assert_difference "rule.activities.count" do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end

    assert_not rule.active
    assert_equal(
      "Rule was disabled because slack team configuration for the organization could be found.",
      rule.activities.order(created_at: :desc).first.action
    )
  end

  def test_message_to_slack_action_deactivates_rule_with_slack_team_channel
    Slack::Web::Client
      .any_instance
      .stubs(:chat_postMessage)
      .raises(Slack::Web::Api::Errors::ChannelNotFound.new("Wrong channel"))

    stub_request(:post, "https://slack.com/api/chat.postMessage")
      .with(
        body: { "channel" => "general", "text" => "Test message to slack", "token" => nil },
        headers: {
          "Accept" => "application/json; charset=utf-8",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "Slack Ruby Client/0.14.6"
        })
      .to_return(status: 200, body: "", headers: {})

    ticket = create :ticket, :with_desc
    create :slack_team, organization: ticket.organization
    rule = create :automation_rule, organization: ticket.organization
    action = create :automation_action, rule: rule, name: "message_to_slack", value: "general", body: "Test message to slack"

    assert_difference "rule.activities.count" do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end

    assert_not rule.active
    assert_equal(
      "Rule was disabled because the provided slack channel could not be reached.",
      rule.activities.order(created_at: :desc).first.action
    )
  end

  def test_that_action_is_not_executed_when_values_are_same_and_action_is_skippable
    ticket = create :ticket
    agent_role = create :organization_role_agent, organization: ticket.organization
    agent = create :user, organization: ticket.organization, role: agent_role
    rule = create :automation_rule, organization: ticket.organization
    action = create :automation_action, rule: rule, name: :assign_agent, actionable: agent
    ticket.update(agent:)

    assert_no_difference "rule.activities.count" do
      Desk::Automation::ActionExecutionService.new(action, ticket).run
    end
  end

  private

    def test_body
      <<~TEXT
      <div>
      Hi {{ticket.requester.name}},
      We have received your ticket {{ticket.number}}.
      Our team at {{ticket.organization.name}} is working really hard to provide you better experience.
      We have taken your issue at {{ticket.priority}} priority.
      We have assigned following tags to the ticket:
      {% for tag in ticket.tags %}{{tag.name}}, {% endfor %}
      Thank you,
      Team {{organization.name}}
      </div>
      TEXT
    end

    def valid_body(ticket)
      <<~TEXT
      <div>\r
      Hi #{ticket.requester.name},\r
      We have received your ticket #{ticket.number}.\r
      Our team at #{ticket.organization.name} is working really hard to provide you better experience.\r
      We have taken your issue at #{ticket.priority} priority.\r
      We have assigned following tags to the ticket:\r
      Charging, Educational, \r
      Thank you,\r
      Team #{ticket.organization.name}\r
      </div>
      TEXT
    end
end
