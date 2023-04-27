# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  class DetailsTagsServiceTest < ActiveSupport::TestCase
    def setup
      @user = create :user
      @organization = @user.organization
      @ticket = create(
        :ticket,
        organization: @organization,
        requester: create(:user),
        agent: @user,
        priority: 2,
        category: "None")
    end

    def test_adds_tags_to_tickets
      tag1 = create(:ticket_tag, organization: @organization).as_json.symbolize_keys
      @ticket.tags.destroy_all
      Desk::Ticketing::DetailsTagsService.new(
        @organization, @ticket,
        tags: [tag1.as_json.symbolize_keys, { name: "tag" }]).process
      assert_equal @ticket.tags.length, 2
    end

    def test_that_activity_is_created_when_tags_are_added
      tag_1 = create :ticket_tag, name: "Urgent", organization: @organization
      tag_2 = create :ticket_tag, name: "Primary", organization: @organization

      options = [
        {
          id: tag_1.id,
          name: tag_1.name
        },
        {
          id: tag_2.id,
          name: tag_2.name
        }
      ]

      assert_difference "@ticket.tags.count", 2 do
        assert_difference "@ticket.activities.count" do
          Desk::Ticketing::DetailsTagsService.new(@organization, @ticket, tags: options).process
        end
      end
    end

    def test_that_activity_is_created_when_tags_are_removed
      tag_1 = create :ticket_tag, name: "Urgent", organization: @organization

      @ticket.update_tags([tag_1])

      assert_difference "@ticket.tags.count", -1 do
        assert_difference "@ticket.activities.count" do
          Desk::Ticketing::DetailsTagsService.new(@organization, @ticket, tags: []).process
        end
      end
    end

    def test_that_activity_is_created_when_tags_are_updated
      tag_1 = create :ticket_tag, name: "Urgent", organization: @organization
      tag_2 = create :ticket_tag, name: "Primary", organization: @organization

      @ticket.update_tags([tag_1])

      options = [
        {
          id: tag_2.id,
          name: tag_2.name
        }
      ]

      assert_no_difference "@ticket.tags.count" do
        assert_difference "@ticket.activities.count" do
          Desk::Ticketing::DetailsTagsService.new(@organization, @ticket, tags: options).process
        end
      end
    end

    def test_that_activity_is_created_when_all_tags_are_cleared
      tag_1 = create :ticket_tag, name: "Urgent", organization: @organization

      @ticket.update_tags([tag_1])

      assert_difference "@ticket.tags.count", -1 do
        assert_difference "@ticket.activities.count" do
          Desk::Ticketing::DetailsTagsService.new(@organization, @ticket, tags: []).clear
        end
      end
    end
  end
end
