# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class FieldTest < ActiveSupport::TestCase
      def setup
        @organization = create :organization
      end

      def test_that_ticket_field_is_valid
        text_field = build :ticket_field
        assert text_field.valid?
      end

      def test_that_ticket_field_is_not_valid_without_required_attributes
        text_field = build :ticket_field, agent_label: nil
        assert_not text_field.valid?
      end

      def test_that_ticket_field_with_exiting_name_is_not_valid
        organization = create :organization
        text_field1 = create :ticket_field, organization: organization, agent_label: "What is your name?"
        text_field2 = build :ticket_field, organization: organization, agent_label: "What is your name?"
        assert_not text_field2.valid?
      end

      def test_that_ticket_field_with_exiting_name_is_valid_for_different_organization
        organization = create :organization
        text_field1 = create :ticket_field, organization: organization, agent_label: "What is your name?"
        text_field2 = build :ticket_field, agent_label: "What is your name?"
        assert text_field2.valid?
      end

      def test_that_dropdown_ticket_field_is_valid
        text_field = build :ticket_field, :dropdown
        assert text_field.valid?
      end

      def test_that_float_ticket_field_is_valid
        text_field = build :ticket_field, :float
        assert text_field.valid?
      end

      def test_that_discard_soft_deletes_ticket_field_with_responses
        field = create :ticket_field
        create :ticket_field_response, ticket_field: field

        assert_nil field.deleted_at
        field.discard
        assert_not_nil field.reload.deleted_at
      end

      def test_that_discard_hard_deletes_ticket_field_without_responses
        field = create :ticket_field, state: "inactive"

        field.discard
        assert_raise ActiveRecord::RecordNotFound do
          field.reload
        end
      end

      def test_can_not_delete_system_fields
        category_field = create :ticket_field, :system_category, organization: @organization

        assert_raise ActiveRecord::RecordNotDestroyed do
          category_field.destroy!
        end
      end

      def test_system_fields_can_not_be_inactivated
        category_field = create :ticket_field, :system_category, organization: @organization

        assert_raise ActiveRecord::RecordNotSaved do
          category_field.update!(state: :inactive)
        end
      end

      def test_system_fields_can_not_be_duplicated
        create :ticket_field, :system_subject, organization: @organization

        ticket_field = @organization.ticket_fields.create(kind: "system_subject", agent_label: "System subject")
        assert_includes ticket_field.errors[:kind], "is a system_field, So, you can not add additional fields"
      end

      def test_system_field_can_be_recreated_after_being_used_in_atleast_one_ticket_and_then_destroyed
        organization = create :organization
        text_field1 = create :ticket_field, organization: organization, agent_label: "What is your name?",
          deleted_at: Time.current
        text_field2 = build :ticket_field, organization: organization, agent_label: "What is your name?"
        assert text_field2.valid?
      end
    end
  end
end
