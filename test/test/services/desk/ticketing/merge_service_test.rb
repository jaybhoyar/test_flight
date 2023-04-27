# frozen_string_literal: true

require "test_helper"

class Desk::Ticketing::MergeServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @user = create :user, organization: @organization
    create_multiple_tickets
  end

  def test_process
    options = {
      is_primary_comment_public: true,
      is_secondary_comment_public: true,
      primary_comment: "Requests ##{@ticket_2.number}, ##{@ticket_3.number}, #00000 will be merged into this request",
      secondary_comment: "This request will be closed and merged into ##{@ticket_1.number}",
      secondary_ticket_ids: [@ticket_2.id, @ticket_3.id]
    }

    assert_equal 3, @ticket_2.comments.count
    assert_equal 3, @ticket_3.comments.count

    service = Desk::Ticketing::MergeService.new(@ticket_1, @user, options)
    assert_difference "Comment.count", 5 do
      service.process
    end

    # Test statuses
    assert_equal "open", @ticket_1.reload.status
    assert_equal "closed", @ticket_2.reload.status
    assert_equal "closed", @ticket_3.reload.status

    # Test that secondary ticket details are added on primary tickets as note
    secondary_ticket_detail_comments = @ticket_1.comments.where(comment_type: "note").order(created_at: :asc).last(2)
    comment_1 = secondary_ticket_detail_comments.first
    comment_2 = secondary_ticket_detail_comments.last

    assert comment_1.info.to_s.include? "<strong>Subject:</strong> Issue - Ticket"
    assert comment_2.info.to_s.include? "<strong>Subject:</strong> Issue - Ticket"

    # Test comments have moved
    # 2 remaining comments
    #  - 1 description
    #  - 1 merge info comment
    assert_equal 2, @ticket_2.comments.count
    assert_equal 2, @ticket_3.comments.count

    primary_comment = @ticket_1.comments.latest.first
    secondary_comment_1 = @ticket_2.comments.latest.first
    secondary_comment_2 = @ticket_3.comments.latest.first

    # Test added comment type on primary ticket
    assert primary_comment.reply?

    # Test added comment type on secondary tickets
    assert secondary_comment_1.reply?
    assert secondary_comment_2.reply?

    assert primary_comment.info.to_s.include? "##{@ticket_2.number}"
    assert primary_comment.info.to_s.include? "##{@ticket_3.number}"

    assert secondary_comment_1.info.to_s.include? "##{@ticket_1.number}"
    assert secondary_comment_2.info.to_s.include? "##{@ticket_1.number}"
  end

  def test_that_notes_are_created_instead_of_replies
    options = {
      is_primary_comment_public: false,
      is_secondary_comment_public: false,
      primary_comment: "Requests ##{@ticket_2.number}, ##{@ticket_3.number} will be merged into this request",
      secondary_comment: "This request will be closed and merged into ##{@ticket_1.number}",
      secondary_ticket_ids: [@ticket_2.id, @ticket_3.id]
    }

    service = Desk::Ticketing::MergeService.new(@ticket_1, @user, options)
    assert_difference "Comment.count", 5 do
      service.process
    end

    assert_equal "open", @ticket_1.reload.status
    assert_equal "closed", @ticket_2.reload.status
    assert_equal "closed", @ticket_3.reload.status

    assert @ticket_1.comments.latest.first.note?
    assert @ticket_2.comments.latest.first.note?
    assert @ticket_3.comments.latest.first.note?
  end

  private

    def create_multiple_tickets
      @ticket_1 = create :ticket,
        status: "open",
        subject: "Issue - Ticket 1",
        organization: @organization,
        requester: create(:user, organization: @organization),
        created_at: 3.hours.ago

      @ticket_2 = create :ticket,
        status: "open",
        subject: "Issue - Ticket 2",
        organization: @organization,
        requester: create(:user, organization: @organization),
        created_at: 2.hours.ago

      @ticket_3 = create :ticket,
        status: "open",
        subject: "Issue - Ticket 3",
        organization: @organization,
        requester: create(:user, organization: @organization),
        created_at: 1.hours.ago

      create :comment, :description, ticket: @ticket_1, info: "Ticket 1 description", created_at: 3.hours.ago
      create :comment, :description, ticket: @ticket_2, info: "Ticket 2 description", created_at: 2.hours.ago
      create :comment, :description, ticket: @ticket_3, info: "Ticket 3 description", created_at: 1.hours.ago

      # Reply/Note on tickets
      create :comment, :reply, ticket: @ticket_1, info: "Ticket 1 comment 1"
      create :comment, :reply, ticket: @ticket_1, info: "Ticket 1 comment 2"

      create :comment, :reply, ticket: @ticket_2, info: "Ticket 2 comment 1"
      create :comment, :note, ticket: @ticket_2, info: "Ticket 2 note 1"

      create :comment, :note, ticket: @ticket_3, info: "Ticket 3 note 1"
      create :comment, :note, ticket: @ticket_3, info: "Ticket 3 note 2"
    end
end
