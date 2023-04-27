# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class UpdateTicketFieldsServiceTest < ActiveSupport::TestCase
    def setup
      @organization = create :organization
      @user = create :user, organization: @organization
      @ticket_field = create :ticket_field, organization: @organization
      @ticket = create(
        :ticket,
        organization: @organization,
        requester: create(:user),
        agent: @user,
        priority: 2,
        category: "None")
    end

    def test_that_ticket_fields_data_is_created_for_ticket
      assert_difference "Desk::Ticket::Field::Response.count", 1 do
        Desk::Ticketing::UpdateTicketFieldsService.new(
          @organization,
          @ticket,
          [{ ticket_field_id: @ticket_field.id, value: "Firefox" }]
        ).process
      end
      assert_equal 1, @ticket.ticket_field_responses.count
    end

    def test_that_ticket_fields_data_is_updated_for_ticket
      ticket_field_response = create :ticket_field_response, ticket_field: @ticket_field, owner: @ticket

      assert_equal "Firefox", ticket_field_response.value
      assert_no_difference "Desk::Ticket::Field::Response.count" do
        payload = [
          { ticket_field_id: @ticket_field.id, value: "Safari", id: ticket_field_response.id }
        ]
        Desk::Ticketing::UpdateTicketFieldsService.new(@organization, @ticket, payload).process
      end
      assert_equal "Safari", ticket_field_response.reload.value
    end

    def test_multi_select_fields_can_be_updated
      ticket_field = create(:ticket_field, :multi_select, organization: @organization)
      ticket_field_options = ticket_field.ticket_field_options

      payload = [
        {
          ticket_field_id: ticket_field.id, ticket_field_option_id: ticket_field_options[0].id
        },
        {
          ticket_field_id: ticket_field.id, ticket_field_option_id: ticket_field_options[2].id
        }
      ]
      assert_difference "Desk::Ticket::Field::Response.count", 2 do
        Desk::Ticketing::UpdateTicketFieldsService.new(@organization, @ticket, payload).process
      end

      assert_difference "Desk::Ticket::Field::Response.count", -1 do
        payload = [
          ticket_field_id: ticket_field.id, id: ticket_field.ticket_field_responses.first.id, _destroy: true
        ]
        Desk::Ticketing::UpdateTicketFieldsService.new(@organization, @ticket, payload).process
      end
    end

    def test_that_value_of_date_type_ticket_field_can_be_unset
      ticket_field = create(:ticket_field, :date, organization: @organization)
      response = create :ticket_field_response, owner: @ticket, ticket_field: ticket_field, value: "01-01-2021"
      payload = [
        ticket_field_id: ticket_field.id,
        id: response.id,
        value: nil,
        _destroy: true
      ]

      Desk::Ticketing::UpdateTicketFieldsService.new(
        @organization,
        @ticket,
        payload
      ).process

      assert_equal 0, @ticket.ticket_field_responses.count
    end
  end
end
