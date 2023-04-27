# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class ResponseTimeTest < ActiveSupport::TestCase
      def setup
        @ticket = create :ticket
        @agent_role = create :organization_role_agent, organization: @ticket.organization
      end

      test "valid ticket response time" do
        assert Desk::Ticket::ResponseTime.new(ticket_id: @ticket.id).valid?
      end

      test "invalid valid ticket status change - case 1" do
        assert_not Desk::Ticket::ResponseTime.new.valid?
      end

      test "ticket.response_time" do
        assert create(:ticket).response_time.present?
      end

      test "response_time record is present for a new ticket" do
        ticket = create(:ticket)
        assert ticket.response_time.present?
        assert ticket.response_time.first_response_time.nil?
        assert ticket.response_time.resolution_time.nil?
      end

      test "Record first_response_time when first comment is posted" do
        ticket = create(:ticket)
        assert ticket.response_time.first_response_time.nil?

        travel_to 15.minutes.since
        agent = create(:user, role: @agent_role, organization: ticket.organization)
        comment = ticket.comments.create! info: "First response text", author: agent
        travel_back

        assert_equal 0.25, ticket.response_time.first_response_time
      end

      test "first_response_time is not changed when comments after the first one are posted" do
        ticket = create(:ticket)

        assert ticket.response_time.first_response_time.nil?

        agent = create(:user, role: @agent_role, organization: ticket.organization)
        ticket.comments.create! info: "First response text", author: agent

        assert_no_difference "ticket.response_time.first_response_time" do
          ticket.comments.create! info: "Second response text", author: agent
        end
      end

      test "first_response_time is not recorded when first comment is posted by a customer" do
        organization = create(:organization)
        customer = create(:user, role: nil, organization:)
        ticket = create(:ticket, requester: customer, organization:)

        assert ticket.response_time.first_response_time.nil?

        assert_no_changes "ticket.response_time.first_response_time" do
          ticket.comments.create! info: "Second response text", author: customer
        end
      end

      test "Record resolution_time when status changes to 'resolved'" do
        ticket = create(:ticket)
        assert ticket.response_time.resolution_time.nil?

        ticket.update! status: "resolved"

        assert ticket.response_time.resolution_time.present?
      end

      test "Update resolution_time each time when status changes to 'resolved'" do
        ticket = create(:ticket)
        assert ticket.response_time.resolution_time.nil?

        ticket.update! status: "resolved"

        travel_to 2.hours.since
        ticket.update! status: "open"

        travel_to 2.hours.since

        assert_changes "ticket.response_time.resolution_time" do
          ticket.update! status: "resolved"
        end

        travel_back
      end

      test "resolution_time not changed on status changes other than to 'resolved'" do
        ticket = create(:ticket)
        assert ticket.response_time.resolution_time.nil?

        ticket.update! status: "resolved"

        travel_to 2.hours.since
        ticket.update! status: "open"

        travel_to 2.hours.since
        assert_no_changes "ticket.response_time.resolution_time" do
          @ticket.update! status: "closed"
        end

        travel_back
      end
    end
  end
end
