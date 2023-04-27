# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class StatusChangeTest < ActiveSupport::TestCase
      def setup
        @ticket = create :ticket
      end

      test "valid ticket status change" do
        assert StatusChange.new(ticket_id: @ticket.id, status: "resolved").valid?
      end

      test "invalid valid ticket status change - case 1" do
        assert_not StatusChange.new(status: "resolved").valid?
      end

      test "invalid valid ticket status change - case 2" do
        assert_not StatusChange.new(ticket_id: @ticket.id).valid?
      end

      test "invalid valid ticket status change - case 3" do
        assert_not StatusChange.new.valid?
      end

      test "ticket.status_changes" do
        status_change = StatusChange.create(ticket_id: @ticket.id, status: "resolved")
        assert_includes @ticket.status_changes, status_change
      end

      test "status change created when ticket is created" do
        assert_equal 1, @ticket.status_changes.count

        status_change = @ticket.status_changes.first
        assert_equal @ticket.status, status_change.status
        assert_not status_change.created_at.nil?
      end

      test "status change created when status is changed" do
        assert_difference "@ticket.status_changes.count", 1 do
          @ticket.update! status: "closed"
        end

        status_change = @ticket.status_changes.where(status: @ticket.status).first
        assert status_change
        assert_not status_change.created_at.nil?
      end
    end
  end
end
