# frozen_string_literal: true

require "test_helper"

module Desk::Ticketing
  module Filter
    class FilterServiceTest < ActiveSupport::TestCase
      def setup
        travel_to DateTime.parse("6:00 PM")

        @organization = create :organization
        @brad = create :user, organization: @organization
        @ethan = create :user, organization: @organization

        create :ticket, :with_desc,
          organization: @organization,
          requester: @ethan,
          agent: @brad,
          subject: "Unable to generate invoice",
          priority: 2,
          status: "new",
          category: "None",
          number: 1,
          channel: "email",
          created_at: Date.current

        create :ticket, :with_desc,
          organization: @organization,
          requester: @ethan,
          agent: @brad,
          subject: "Unable to pay via stripe",
          category: "Questions",
          number: 2,
          channel: "email",
          priority: 0,
          status: "new",
          created_at: Date.current - 2.day

        create :ticket, :with_desc,
          organization: @organization,
          requester: @ethan,
          agent: @ethan,
          subject: "Unable to login",
          category: "Problem",
          priority: 1,
          status: "open",
          number: 4,
          channel: "twitter",
          created_at: Date.current + 1.month

        create :ticket, :with_desc,
          organization: @organization,
          requester: @ethan,
          agent: @ethan,
          subject: "Unable to generate reset password mail",
          category: "Feature Request",
          priority: 0,
          status: "new",
          number: 5,
          channel: "twitter",
          created_at: Date.current - 1.day
      end

      def teardown
        travel_back
      end

      def test_status_filter
        ticket_filter_params = { filter_by: { "0" => { node: "status", rule: "is", value: "open" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count

        ticket_filter_params = { filter_by: { "0" => { node: "status", rule: "is", value: "new,open" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 4, tickets.count
      end

      def test_priority_filter
        ticket_filter_params = { filter_by: { "0" => { node: "priority", rule: "is", value: "medium" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count

        ticket_filter_params = { filter_by: { "0" => { node: "priority", rule: "is", value: "low,medium" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 3, tickets.count
      end

      def test_status_and_priority_filter
        ticket_filter_params = {
          filter_by: {
            "0" => { node: "status", rule: "is", value: "new" },
            "1" => { node: "priority", rule: "is", value: "low" }
          }
        }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 2, tickets.count
      end

      def test_category_filter
        ticket_filter_params = { filter_by: { "0" => { node: "category", rule: "is", value: "Questions" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count

        ticket_filter_params = {
          filter_by: {
            "0" => {
              node: "category", rule: "is",
              value: "Questions,Feature Request"
            }
          }
        }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 2, tickets.count
      end

      def test_agent_filter
        ticket_filter_params = { filter_by: { "0" => { node: "agent_id", rule: "is", value: @ethan.id } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 2, tickets.count

        ticket_filter_params = {
          filter_by: {
            "0" => {
              node: "agent_id", rule: "is",
              value: [@brad, @ethan].map(&:id).join(",")
            }
          }
        }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 4, tickets.count
      end

      def test_created_at_filter
        tickets = @organization.tickets
        tickets[0].update(created_at: Date.current - 60.days)
        tickets[1].update(created_at: Date.current - 90.days)
        tickets[2].update(created_at: Date.current - 1.days)
        tickets[3].update(created_at: Date.current)

        ticket_filter_params = { filter_by: { "0" => { node: "created_at", rule: "is", value: "yesterday" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count

        ticket_filter_params = { filter_by: { "0" => { node: "created_at", rule: "is", value: "today" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count

        ticket_filter_params = { filter_by: { "0" => { node: "created_at", rule: "is", value: "24.hours.ago" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count

        ticket_filter_params = { filter_by: { "0" => { node: "created_at", rule: "is", value: "60.days.ago" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 3, tickets.count
      end

      def test_category_filter_based_on_selected_time_period
        from = "04-04-2020".to_time
        to = from + 10.days

        create(:ticket, created_at: from + 5.days, organization: @organization)
        create(:ticket, created_at: from + 6.days, organization: @organization)
        create(:ticket, created_at: Date.current, organization: @organization)

        ticket_filter_params = {
          filter_by: {
            "0" => {
              node: "created_at",
              rule: "is",
              value: "04-04-2020, 14-04-2020"
            }
          }
        }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 2, tickets.count
      end

      def test_filtering_tickets_based_on_tag_ids
        tickets_batch = @organization.tickets.first(3)
        tag_1 = create :ticket_tag, organization: @organization, name: "Billing"
        tag_2 = create :ticket_tag, organization: @organization, name: "Shilling"

        tickets_batch[0].update(tags: [tag_1])
        tickets_batch[1].update(tags: [tag_2])
        tickets_batch[2].update(tags: [tag_1, tag_2])

        ticket_filter_params = {
          filter_by: {
            "0" => { node: "taggings.tag_id", rule: "is", value: tag_1.id }
          },
          include_models: { "0" => { value: "taggings" } },
          default_filter_by: "unfiltered"
        }
        assert_equal 2, ticket_filter_service(@organization, ticket_filter_params).count

        ticket_filter_params = {
          filter_by: {
            "0" => { node: "taggings.tag_id", rule: "is", value: "#{tag_1.id},#{tag_2.id}" }
          },
          include_models: { "0" => { value: "taggings" } },
          default_filter_by: "unfiltered"
        }

        assert_equal 1, ticket_filter_service(@organization, ticket_filter_params).count
      end

      def test_filtering_tickets_based_on_subject_and_comment_info
        ticket_filter_params = {
          filter_by: {
            "0" => {
              node: "keyword",
              rule: "contains",
              value: "unable to pay"
            }
          }
        }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 1, tickets.count
      end

      def test_channel_filter
        ticket_filter_params = { filter_by: { "0" => { node: "channel", rule: "is", value: "twitter" } } }
        tickets = ticket_filter_service(@organization, ticket_filter_params)
        assert_equal 2, tickets.count
      end

      private

        def ticket_filter_service(organization, options, tickets_to_filter = @organization.tickets)
          Desk::Ticketing::Filter::FilterService.new(organization, options, tickets_to_filter).process
        end
    end
  end
end
