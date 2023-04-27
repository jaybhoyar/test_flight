# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class ColliderServiceTest < ActiveSupport::TestCase
    def setup
      @organization_role = create :organization_role_agent
      @user = create(:user, role: @organization_role)
      @organization = @user.organization
      @ticket = create(:ticket, organization: @organization)
    end

    def test_collider_is_marked
      service = ColliderService.new(@ticket, @user)
      assert_difference "@ticket.ticket_colliders.count" do
        service.mark
      end

      assert @ticket.ticket_colliders.first.view?
    end

    def test_collider_is_updated_when_it_exists
      collider = create :desk_ticket_collider, ticket: @ticket, user: @user
      service = ColliderService.new(@ticket, @user)

      assert collider.view?
      assert_no_difference "@ticket.ticket_colliders.count" do
        service.mark("reply")
      end

      assert collider.reload.reply?
    end

    def test_collider_records_are_cleared
      create :desk_ticket_collider, ticket: @ticket, user: @user
      create :desk_ticket_collider, user: @user

      service = ColliderService.new(@ticket, @user)

      assert_difference "@ticket.ticket_colliders.count", -1 do
        service.clear
      end
    end
  end
end
