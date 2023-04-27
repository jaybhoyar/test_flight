# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class TicketCreatorServiceTest < ActiveSupport::TestCase
    include ActionCable::TestHelper

    setup do
      @user = create :user
      @organization = @user.organization
      @subject = "Please create a ticket for me, Please!"
      @content = "This is the content"
    end

    def test_create_ticket_by_agent_on_behalf_of_a_customer
      valid_email = "user@customer.com"
      options = {
        customer_email: valid_email,
        priority: "high",
        category: "Incident",
        channel: "ui"
      }
      ticket = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content, @organization, nil,
        nil, nil, options).run
      assert_equal @subject, ticket.subject
      assert_equal @user, ticket.submitter
      assert_equal valid_email, ticket.requester.email
      assert_equal 1, ticket.status_changes.count
      assert_equal "new", ticket.status_changes.first.status
    end

    def test_create_ticket_by_customer
      valid_email = "user@customer.com"
      options = {
        customer_email: valid_email,
        priority: "high",
        category: "Incident",
        channel: "ui"
      }
      ticket = Desk::Ticketing::TicketCreatorService.new(
        nil, @subject, @content, @organization, nil, nil, nil,
        options).run
      assert_equal @subject, ticket.subject
      assert_equal ticket.submitter.email, ticket.requester.email
    end

    def test_create_ticket_by_agent
      options = {
        priority: "high",
        category: "Incident",
        channel: "ui"
      }
      ticket = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content, @organization, nil,
        nil, nil, options).run
      assert_equal @subject, ticket.subject
      assert_equal ticket.submitter.email, ticket.requester.email
      assert_equal @user, ticket.submitter
    end

    def test_should_be_able_to_create_a_new_ticket_with_a_valid_customer_email_who_belongs_to_different_organization
      new_organization = create(:organization)
      valid_email = "user@customer.com"
      options = {
        customer_email: valid_email,
        priority: "high",
        category: "Incident",
        channel: "ui"
      }
      new_ticket = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content, new_organization,
        nil, nil, nil, options).run
      ticket = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content, @organization, nil,
        nil, options).run
      assert_equal @subject, new_ticket.subject
      assert_equal @subject, ticket.subject
    end

    def test_should_not_be_able_to_create_a_new_ticket_if_email_is_empty
      empty_email = ""
      options = {
        customer_email: empty_email,
        priority: "high",
        category: "Incident",
        channel: "ui"
      }

      ticket = Desk::Ticketing::TicketCreatorService.new(
        nil, @subject, @content, @organization, nil, nil, nil,
        options).run
      assert_not ticket.persisted?
      assert_equal ["Requester must exist", "Comments author must exist"], ticket.errors.full_messages
    end

    def test_should_not_be_able_to_create_a_new_ticket_if_email_id_is_incorrect
      invalid_email = "12.com"
      options = {
        customer_email: invalid_email,
        priority: "high",
        category: "Incident",
        channel: "ui"
      }

      assert_raises ActiveRecord::RecordInvalid do
        Desk::Ticketing::TicketCreatorService.new(
          @user, @subject, @content, @organization, nil, nil, nil,
          options).run
      end
    end

    def test_should_be_able_to_create_a_new_ticket_and_a_comment_with_a_message_id
      email = "customer@example.com"
      options = {
        customer_email: email,
        priority: "high",
        category: "Incident",
        channel: "ui"
      }

      ticket_create_object = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content,
        @organization, nil, nil, nil, options)
      @ticket = ticket_create_object.run

      assert_equal @subject, @ticket.subject
      assert_not_empty @ticket.comments.first.message_id
    end

    def test_that_ticket_is_valid_with_ticket_fields_data
      field = create :ticket_field, is_required: true, organization: @organization
      field2 = create :ticket_field, :dropdown, is_required: true, organization: @organization

      contact_email = "customer@example.com"
      options = {
        customer_email: contact_email,
        priority: "high",
        category: "Incident",
        channel: "ui",
        ticket_field_responses_attributes: [
          { ticket_field_id: field.id, value: "Chrome" },
          { ticket_field_id: field2.id, ticket_field_option_id: field2.ticket_field_options.first.id }
        ]
      }

      ticket_create_object = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content,
        @organization, nil, nil, nil, options)

      assert_difference "Ticket.count" do
        assert_difference "Desk::Ticket::Field::Response.count", 2 do
          @ticket = ticket_create_object.run
        end
      end
    end

    def test_that_ticket_is_created_without_data_of_required_ticket_fields
      field = create :ticket_field, is_required: true, organization: @organization

      options = {
        customer_email: "matt@example.com",
        priority: "high",
        category: "Incident",
        channel: "ui"
      }

      ticket_create_object = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content,
        @organization, nil, nil, nil, options)

      assert_difference "Ticket.count" do
        @ticket = ticket_create_object.run
      end
    end

    def test_that_ticket_is_invalid_without_proper_data_for_dropdown_type_ticket_fields
      field = create :ticket_field, :dropdown, is_required: true, organization: @organization

      options = {
        customer_email: "matt@example.com",
        priority: "high",
        category: "Incident",
        channel: "ui",
        ticket_field_responses_attributes: [
          { ticket_field_id: field.id, value: field.ticket_field_options.first.name }
        ]
      }

      ticket_create_object = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content,
        @organization, nil, nil, nil, options)

      @ticket = ticket_create_object.run

      assert @ticket.invalid?
      assert_equal ["Ticket field responses ticket field option can't be blank"], @ticket.errors.full_messages
    end

    def test_that_ticket_is_invalid_without_value_for_ticket_field
      field = create :ticket_field, is_required: true, organization: @organization

      options = {
        customer_email: "matt@example.com",
        priority: "high",
        category: "Incident",
        channel: "ui",
        ticket_field_responses_attributes: [
          { ticket_field_id: field.id, value: nil }
        ]
      }

      ticket_create_object = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content,
        @organization, nil, nil, nil, options)

      @ticket = ticket_create_object.run

      assert @ticket.invalid?
      assert_equal ["Ticket field responses value can't be blank"], @ticket.errors.full_messages
    end

    def test_that_ticket_is_valid_without_value_for_dropdown_ticket_field
      field = create :ticket_field, :dropdown, is_required: true, organization: @organization

      options = {
        customer_email: "matt@example.com",
        priority: "high",
        category: "Incident",
        channel: "ui",
        ticket_field_responses_attributes: [
          { ticket_field_id: field.id, ticket_field_option_id: field.ticket_field_options.first.id, value: nil }
        ]
      }

      ticket_create_object = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content,
        @organization, nil, nil, nil, options)

      assert_difference ["Ticket.count", "Desk::Ticket::Field::Response.count"] do
        @ticket = ticket_create_object.run
      end
    end

    def test_that_after_creating_ticket_matching_rule_is_applied
      tag = create :ticket_tag, name: "billing", organization: @organization
      agent = create :user, organization: @organization
      refund_rule = create :automation_rule, :on_ticket_create,
        name: "Assign tag billing when subject contains refund",
        organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: refund_rule
      create :automation_action, rule: refund_rule, name: "set_tags", tag_ids: [tag.id], status: nil
      create :automation_action, rule: refund_rule, name: "change_ticket_status", status: "resolved"
      create :automation_action, rule: refund_rule, name: "assign_agent", actionable: agent

      refund_ticket = nil
      Sidekiq::Testing.inline! do
        options = {
          priority: "high",
          category: "Incident",
          channel: "ui"
        }
        subject = "When can I expect my refund?"
        refund_ticket = Desk::Ticketing::TicketCreatorService.new(
          @user, subject, @content, @organization,
          nil, nil, nil, options).run
      end

      assert_not_empty refund_ticket.reload.tags
      assert_equal "resolved", refund_ticket.status
      assert_equal agent.id, refund_ticket.agent_id
    end

    def test_that_matching_rules_are_applied_in_correct_order
      tag = create :ticket_tag, name: "billing", organization: @organization

      rule_1 = create :automation_rule, :on_ticket_create, name: "Rule 1", organization: @organization
      create :automation_condition_subject_contains_refund, conditionable: rule_1
      create :automation_action, rule: rule_1, name: "change_ticket_status", status: "waiting_on_customer"

      rule_2 = create :automation_rule, :on_ticket_create, name: "Rule 2", organization: @organization
      create :automation_condition, conditionable: rule_2, field: "status", verb: "is", value: "2"
      create :automation_action, rule: rule_2, name: "set_tags", tag_ids: [tag.id]

      refund_ticket = nil
      Sidekiq::Testing.inline! do
        options = {
          priority: "high",
          category: "Incident",
          channel: "ui"
        }
        subject = "When can I expect my refund?"
        assert_difference ["::Desk::Automation::ExecutionLogEntry.count"], 2 do
          refund_ticket = Desk::Ticketing::TicketCreatorService.new(
            @user, subject, @content,
            @organization, nil, nil, nil, options).run
        end
      end

      assert_not_empty refund_ticket.reload.tags
      assert_equal "waiting_on_customer", refund_ticket.status
      assert_includes refund_ticket.tags, tag
    end

    def test_create_ticket_from_email_stores_attachment
      @email_configuration = create(:email_configuration, organization: @organization)
      file = File.open(Rails.root.join("public", "apple-touch-icon.png"))
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: "image.png", content_type: "image/png")

      options = {
        attachments: [blob]
      }

      ticket = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content, @organization,
        @email_configuration, nil, nil, options).run

      comment = ticket.latest_comment
      assert_equal @subject, ticket.subject
      assert_equal 1, comment.attachments.count

      blob = comment.attachments.first.blob
      assert_equal "image.png", blob.filename.to_s
      assert_equal "image/png", blob.content_type
      assert_nothing_raised { blob.download }
    end

    def test_event_is_broadcasted_when_new_ticket_is_created
      valid_email = "jack@example.com"
      options = {
        customer_email: valid_email,
        priority: "low",
        channel: "ui"
      }
      ticket = Desk::Ticketing::TicketCreatorService.new(
        @user, @subject, @content, @organization, nil,
        nil, nil, options).run

      assert_broadcasts "tickets-#{@organization.subdomain}", 1
    end
  end
end
