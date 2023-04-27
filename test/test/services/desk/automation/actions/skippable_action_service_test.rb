# frozen_string_literal: true

require "test_helper"

class Desk::Automation::Actions::SkippableActionServiceTest < ActiveSupport::TestCase
  def setup
    organization = create :organization
    agent_role = create :organization_role_agent, organization: organization
    @agent = create :user, organization: organization, role: agent_role
    rule = create :automation_rule, organization: organization
    @action = create :automation_action, name: :assign_agent, rule: rule, actionable: @agent
    @ticket = create :ticket, organization: organization
    @service = ::Desk::Automation::Actions::SkippableActionService
  end

  def test_that_action_is_skippable_when_values_match
    @ticket.update(agent: @agent)

    assert @service.new(@action, @ticket).skippable?
  end

  def test_that_action_is_not_skippable_when_values_doesnt_match
    assert_not @service.new(@action, @ticket).skippable?
  end

  def test_that_action_is_not_skippable_when_action_name_not_skippable
    tag = create :ticket_tag, name: "Test"
    @action.update(name: :set_tags, tags: [tag])
    @ticket.tags = [tag]

    assert_not @service.new(@action, @ticket).skippable?
  end
end
