# frozen_string_literal: true

require "test_helper"
module Desk
  class ApplyTimeBasedAutomationRulesWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      Sidekiq::Testing.inline!

      @user = create :user
      organization = @user.organization

      @tag = create :ticket_tag, name: "billing", organization: organization

      rule = create :automation_rule,
        name: "Assign ticket to Ethan Hunt when ticket is Open for more than 4 hours",
        organization: organization, performer: :system
      create :desk_core_condition, :time_based, conditionable: rule, field: "status.hours.open", verb: "greater_than", value: "4"
      create :automation_action, rule: rule, name: "set_tags", tag_ids: [@tag.id], status: nil
      create :automation_event, name: :time_based, rule: rule

      @ticket = create :ticket, subject: "Please refund me urgently.",
        organization: organization,
        requester: create(:user),
        agent: create(:user),
        priority: 2,
        category: "None",
        created_at: Time.current.beginning_of_day

      create :activity, trackable: @ticket, owner: nil,
        key: "activity.ticket.update.status",
        action: "Status was changed from New to Open",
        created_at: Time.current - 5.hours
    end

    def test_that_rule_is_applied_on_matching_ticket
      assert_empty @ticket.tags

      assert_difference "::Desk::Automation::ExecutionLogEntry.count" do
        ApplyTimeBasedAutomationRulesWorker.new.perform()
      end

      @ticket.reload
      assert_equal 1, @ticket.tags.count
      assert_equal @tag.name, @ticket.tags.first.name
    end
  end
end
