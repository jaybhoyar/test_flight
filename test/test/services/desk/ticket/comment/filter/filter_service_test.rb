# frozen_string_literal: true

require "test_helper"

class Comment
  module Filter
    class FilterServiceTest < ActiveSupport::TestCase
      def setup
        @organization = create(:organization)
        ticket = create(
          :ticket,
          organization: @organization,
          requester: create(:user, organization: @organization),
          agent: create(:user, organization: @organization),
          number: 1,
          category: "Questions")
        User.current = create(:user, organization: @organization)

        @comment_by_agent = create(:comment, ticket:)
        @comment_by_customer = create(
          :comment, author: create(:user, organization: @organization),
          ticket:)
      end

      def test_all_comments_without_filters
        params = ActionController::Parameters.new(comment: { filter_by: {} })
        comments = comment_filter_service(@organization, comment_filter_params(params))
        assert_equal 2, comments.count
      end

      def test_author_type_filter
        params = ActionController::Parameters.new(
          comment: {
            filter_by: {
              "0" => {
                node: "author_type", rule: "is",
                value: "User"
              }
            }
          })
        comments = comment_filter_service(@organization, comment_filter_params(params))
        assert_equal 2, comments.count
      end

      def test_author_id_filter
        params = ActionController::Parameters.new(
          comment: {
            filter_by: {
              "0" => {
                node: "author_id", rule: "is",
                value: @comment_by_agent.author_id
              }
            }
          })
        comments = comment_filter_service(@organization, comment_filter_params(params))
        assert_equal 1, comments.count

        params = ActionController::Parameters.new(
          comment: {
            filter_by: {
              "0" => {
                node: "author_id", rule: "is",
                value: "#{@comment_by_agent.author_id},#{@comment_by_customer.author_id}"
              }
            }
          })
        comments = comment_filter_service(@organization, comment_filter_params(params))
        assert_equal 2, comments.count
      end

      def test_comment_type_filter
        params = ActionController::Parameters.new(
          comment: {
            filter_by: {
              "0" => {
                node: "comment_type", rule: "is",
                value: "reply"
              }
            }
          })
        comments = comment_filter_service(@organization, comment_filter_params(params))
        assert_equal 2, comments.count

        params = ActionController::Parameters.new(
          comment: {
            filter_by: {
              "0" => {
                node: "comment_type", rule: "is",
                value: "forward,note"
              }
            }
          })
        comments = comment_filter_service(@organization, comment_filter_params(params))
        assert_equal 0, comments.count
      end

      private

        def comment_filter_service(organization, options)
          Desk::Ticket::Comment::Filter::FilterService.new(organization, options).process
        end

        def comment_filter_params(params)
          params.require(:comment).permit(
            filter_by: [:node, :rule, :value]
          )
        end
    end
  end
end
