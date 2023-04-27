# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Desk::Ticketing
  class UpdateTicketServiceTest < ActiveSupport::TestCase
    def setup
      @requester = create :user
      @organization = @requester.organization
      @jason = create :user, :agent, organization: @organization
      @ticket = create(
        :ticket, :with_desc, organization: @organization, requester: @requester, agent: @jason,
        priority: 2, category: "None")
    end

    def test_ticket_updated
      new_subject = "Invoice issue in spinkart"
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, subject: new_subject).process
      assert_equal @ticket.subject, new_subject
    end

    def test_that_description_is_updated
      new_desc = "Invoice issue in spinkart"
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, description: new_desc).process
      assert_equal @ticket.description, new_desc
    end

    def test_that_attachments_are_removed
      io = File.open(Rails.root.join("public", "apple-touch-icon.png"))

      description_comment = @ticket.comments.description.first
      3.times do
        description_comment.attachments.attach(io:, content_type: "image/png", filename: "apple-touch-icon")
      end

      assert_equal 3, description_comment.reload.attachments.count

      Desk::Ticketing::UpdateTicketService.new(
        @organization, @ticket, @requester,
        deleted_attachments: [description_comment.attachments.first.id]).process
      assert_equal 2, description_comment.reload.attachments.count
    end

    def test_that_attachments_are_added
      description_comment = @ticket.comments.description.first
      assert_equal 0, description_comment.attachments.count

      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("random text"), filename: "random.txt")

      Desk::Ticketing::UpdateTicketService.new(
        @organization, @ticket, @requester,
        options: { attachments: [blob.signed_id] }).process
      assert_equal 1, description_comment.reload.attachments.count
    end

    def test_addition_of_new_tag
      tag = create(:ticket_tag, organization: @organization)
      options = { tags: [{ id: tag.id, name: tag.name }] }
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, options).process
      assert_equal @ticket.tags.count, 1
    end

    def test_removal_of_existing_tag
      tags = create_list(:ticket_tag, 2, organization: @organization)
      assert_difference -> { @ticket.tags.count } => 2 do
        @ticket.update(tags:)
      end

      options = { tags: [{ id: tags[0].id, name: tags[0].name }] }
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, options).process

      assert_equal @ticket.tags.count, 1
    end

    def test_removal_all_tag
      tags = create_list(:ticket_tag, 2, organization: @organization)
      @ticket.update(tags:)

      assert_equal @ticket.tags.count, 2

      options = { "tags" => [] }
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, options).process

      assert_equal @ticket.tags.count, 0
    end

    def test_removal_all_tag_should_update_ticket_count_in_tag
      tags = create_list(:ticket_tag, 2, organization: @organization)
      @ticket.update(tags:)

      assert_equal tags[1].tickets.not_spam.not_trash.count, 1

      options = { "tags" => [] }
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, options).process
      tags.each { |tag| tag.reload }
      assert_equal tags[1].tickets.not_spam.not_trash.count, 0
    end

    def test_addition_of_new_tag_should_update_ticket_count_in_tag
      tag = create(:ticket_tag, organization: @organization)
      assert_equal tag.tickets.not_spam.not_trash.count, 0
      options = { tags: [{ id: tag.id, name: tag.name }] }
      Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, options).process
      assert_equal tag.tickets.not_spam.not_trash.count, 1
    end

    def test_that_automation_rules_are_applied_on_ticket_updation_for_any_performer
      Sidekiq::Testing.inline!

      @ticket.update(status: "resolved")

      rule_1 = create :automation_rule, :on_ticket_update,
        performer: :any,
        name: "Mark ticket as waiting on customer",
        organization: @organization

      group_1 = create :automation_condition_group, rule: rule_1
      create :automation_condition, conditionable: group_1, field: "status", verb: "is", value: "resolved"
      create :automation_action, rule: rule_1, name: "change_ticket_status", status: "waiting_on_customer"

      rule_2 = create :automation_rule, :on_ticket_update,
        performer: :any,
        name: "Mark priority as urgent",
        organization: @organization

      group_2 = create :automation_condition_group, rule: rule_2
      create :automation_condition, conditionable: group_2, field: "status", verb: "is", value: "resolved"
      create :automation_action, rule: rule_2, name: "change_ticket_priority", value: "urgent"

      assert_equal "resolved", @ticket.status
      assert_equal "high", @ticket.priority

      assert_difference "::Desk::Automation::ExecutionLogEntry.count", 2 do
        Desk::Ticketing::UpdateTicketService.new(
          @organization, @ticket, @requester,
          subject: "Changing to new subject").process
      end

      @ticket.reload
      assert_equal "waiting_on_customer", @ticket.status
      assert_equal "urgent", @ticket.priority
    end

    def test_that_automation_rule_is_applied_on_ticket_updation_by_requester
      Sidekiq::Testing.inline!

      @ticket.update(status: "resolved")

      rule_1 = create :automation_rule, :on_ticket_update,
        performer: :requester,
        name: "Mark ticket as waiting_on_customer",
        organization: @organization

      group_1 = create :automation_condition_group, rule: rule_1
      create :automation_condition, conditionable: group_1, field: "status", verb: "is", value: "resolved"
      create :automation_action, rule: rule_1, name: "change_ticket_status", status: "waiting_on_customer"

      rule_2 = create :automation_rule, :on_ticket_update,
        performer: :agent,
        name: "Mark priority as urgent",
        organization: @organization

      group_2 = create :automation_condition_group, rule: rule_2
      create :automation_condition, conditionable: group_2, field: "status", verb: "is", value: "resolved"
      create :automation_action, rule: rule_2, name: "change_ticket_priority", value: "urgent"

      assert_equal "resolved", @ticket.status
      assert_equal "high", @ticket.priority

      assert_difference "::Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::UpdateTicketService.new(
          @organization, @ticket, @requester,
          subject: "Changing to new subject").process
      end

      @ticket.reload
      assert_equal "waiting_on_customer", @ticket.status
      assert_equal "high", @ticket.priority
    end

    def test_that_automation_rule_is_applied_on_ticket_updation_by_agent
      Sidekiq::Testing.inline!

      @ticket.update(status: "resolved")

      rule_1 = create :automation_rule, :on_ticket_update,
        performer: :requester,
        name: "Mark ticket as waiting_on_customer",
        organization: @organization

      group_1 = create :automation_condition_group, rule: rule_1
      create :automation_condition, conditionable: group_1, field: "status", verb: "is", value: "resolved"
      create :automation_action, rule: rule_1, name: "change_ticket_status", status: "waiting_on_customer"

      rule_2 = create :automation_rule, :on_ticket_update,
        performer: :agent,
        name: "Mark priority as urgent",
        organization: @organization

      group_2 = create :automation_condition_group, rule: rule_2
      create :automation_condition, conditionable: group_2, field: "status", verb: "is", value: "resolved"
      create :automation_action, rule: rule_2, name: "change_ticket_priority", value: "urgent"

      assert_equal "resolved", @ticket.status
      assert_equal "high", @ticket.priority

      assert_difference "::Desk::Automation::ExecutionLogEntry.count", 1 do
        Desk::Ticketing::UpdateTicketService.new(
          @organization, @ticket, @jason,
          subject: "Changing to new subject").process
      end

      @ticket.reload
      assert_equal "resolved", @ticket.status
      assert_equal "urgent", @ticket.priority
    end

    def test_that_when_agent_updates_ticket_it_is_updated_in_last_agent_updated_at
      assert_difference "Activity.count", 1 do
        Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @ticket.agent, subject: "New subject").process
      end

      assert_not_nil @ticket.reload.last_agent_updated_at
    end

    def test_that_when_agent_updates_ticket_it_is_updated_in_last_requester_updated_at
      assert_difference "Activity.count", 1 do
        Desk::Ticketing::UpdateTicketService.new(@organization, @ticket, @requester, subject: "New subject").process
      end

      assert_not_nil @ticket.reload.last_requester_updated_at
    end

    def test_that_survey_emails_are_sent_on_resolved
      ticket = create :ticket, :with_desc, organization: @organization, channel: "email"
      survey = create :default_survey, organization: @organization, email_state: "resolved_ticket"
      question = create :default_question, survey: survey
      create :default_question_scale_choice_1, question: question
      create :default_question_scale_choice_2, question: question
      create :default_question_scale_choice_3, question: question

      update_ticket_service = Desk::Ticketing::UpdateTicketService.new(
        @organization, ticket, @requester,
        status: "resolved"
      )

      stub_request(:any, /fonts.googleapis.com/)

      assert_emails 1 do
        update_ticket_service.process
      end
    end

    def test_that_survey_emails_are_sent_on_closed
      ticket = create :ticket, :with_desc, organization: @organization, channel: "email"
      survey = create :default_survey, organization: @organization, email_state: "closed_ticket"
      question = create :default_question, survey: survey
      create :default_question_scale_choice_1, question: question
      create :default_question_scale_choice_2, question: question
      create :default_question_scale_choice_3, question: question

      update_ticket_service = Desk::Ticketing::UpdateTicketService.new(
        @organization, ticket, @requester,
        status: "closed"
      )

      stub_request(:any, /fonts.googleapis.com/)

      assert_emails 1 do
        update_ticket_service.process
      end
    end
  end
end
