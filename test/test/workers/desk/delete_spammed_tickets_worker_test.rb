# frozen_string_literal: true

require "test_helper"
module Desk
  class DeleteSpammedTicketsWorkerTest < ActiveSupport::TestCase
    require "sidekiq/testing"

    def setup
      @organization_role = create :organization_role_agent
      @user = create(:user, role: @organization_role)
      @organization = @user.organization
      @ticket = create(:ticket, organization: @organization)
      User.current = @user
    end

    def test_deletes_all_tickets_spammed_for_n_days_true
      @ticket.update!(status: "spam")
      Sidekiq::Testing.inline! do
        assert_difference "::Ticket.count", -1 do
          DeleteSpammedTicketsWorker.new(0).perform
        end
      end
    end
  end
end
