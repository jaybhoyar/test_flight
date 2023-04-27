# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class Field::ResponseTest < ActiveSupport::TestCase
      def test_that_ticket_field_response_is_valid
        response = build :ticket_field_response
        assert response.valid?
      end

      def test_that_ticket_field_response_is_not_valid_without_value_if_value_is_required
        response = build :ticket_field_response, :required, value: nil
        assert_not response.valid?
      end

      def test_that_ticket_field_response_is_not_valid_without_ticket_field_option_if_its_a_dropdown_ticket_field
        field = build :ticket_field, :dropdown
        response = build :ticket_field_response, ticket_field: field, ticket_field_option: nil

        assert_not response.valid?
      end

      def test_that_ticket_field_response_is_not_valid_without_owner
        response = build :ticket_field_response, owner: nil
        assert_not response.valid?
      end

      def test_ticket_field_response_is_invalid_for_inacitve_ticket_field
        field = build :ticket_field, state: "inactive"

        response = build :ticket_field_response, ticket_field: field, owner: nil
        assert_not response.valid?
      end
    end
  end
end
