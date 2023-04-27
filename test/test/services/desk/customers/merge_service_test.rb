# frozen_string_literal: true

require "test_helper"
require "set"

class Desk::Customers::MergeServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @user = create :user, organization: @organization
    @required_tags = Set.new
    @tags_after_running_merge_service = Set.new

    create_multiple_customers
    create_tickets_for_customers
    create_customer_notes
    create_customer_tags
    create_customer_1_taggings
    create_customer_2_taggings
  end

  def test_process
    assert_equal 3, @customer1.tickets.count
    assert_equal 3, @customer2.tickets.count

    assert_equal 2, @customer1.email_contact_details.count
    assert_equal 2, @customer2.email_contact_details.count

    assert_equal 1, @customer1.phone_contact_details.count
    assert_equal 1, @customer2.phone_contact_details.count

    assert_equal 1, @customer1.notes.count
    assert_equal 1, @customer2.notes.count

    assert_equal 9, Comment.where(author_id: @customer1.id).count
    assert_equal 9, Comment.where(author_id: @customer2.id).count

    assert_equal 1, User.where(id: @customer1.id).count
    assert_equal 1, User.where(id: @customer2.id).count

    assert_equal 2, Tagging.where(taggable_id: @customer1.customer_detail.id).count
    assert_equal 2, Tagging.where(taggable_id: @customer2.customer_detail.id).count

    Desk::Customers::MergeService.new(@customer1, [@customer2.id], @organization).process

    assert_equal 6, @customer1.tickets.count
    assert_equal 0, @customer2.tickets.count

    assert_equal 4, @customer1.email_contact_details.count
    assert_equal 0, @customer2.email_contact_details.count

    assert_equal 2, @customer1.phone_contact_details.count
    assert_equal 0, @customer2.phone_contact_details.count

    assert_equal 2, @customer1.notes.count
    assert_equal 0, @customer2.notes.count

    assert_equal 18, Comment.where(author_id: @customer1.id).count
    assert_equal 0, Comment.where(author_id: @customer2.id).count

    assert_equal 0, Desk::Ticket::Collider.where(user_id: @customer2.id).count
    assert_equal 0, Desk::Ticket::Follower.where(user_id: @customer2.id).count

    assert_equal 0, CustomerDetail.where(user_id: @customer2.id).count

    assert_equal 1, User.where(id: @customer1.id).count
    assert_equal 0, User.where(id: @customer2.id).count

    assert_equal 3, Tagging.where(taggable_id: @customer1.customer_detail.id).count
    assert_equal 0, Tagging.where(taggable_id: @customer2.customer_detail.id).count

    assert_equal true, check_customer_tags
  end

  def test_merge_service_returns_nil_when_customer_detail_is_nil
    @customer2.customer_detail = nil
    merge_service = Desk::Customers::MergeService.new(@customer1, [@customer2.id], @organization).process
    assert_nil merge_service
  end

  def test_merge_service_when_merged_customer_has_ticket_created_by_himself
    ticket = create(:ticket, submitter: @customer2, requester: @customer2, organization: @organization)

    assert_nothing_raised do
      Desk::Customers::MergeService.new(@customer1, [@customer2.id], @organization).process
    end

    assert_equal ticket.reload.submitter_id, @customer1.id
  end

  def test_merge_service_succeeds_when_primary_customer_detail_is_nil
    @customer1.customer_detail = nil

    assert_nothing_raised do
      Desk::Customers::MergeService.new(@customer1, [@customer2.id], @organization).process
    end
  end

  private

    def create_multiple_customers
      @customer_params_1 = {
        first_name: "Jon",
        customer_detail_attributes: {
          language: "High Valyrian",
          time_zone: "Eastern Time (US & Canada)",
          about: "About jon"
        },
        email_contact_details_attributes: [
          {
            value: "jon@example.com",
            primary: "true"
          },
          {
            value: "jon@gmail.com",
            primary: "false"
          }
        ],
        link_contact_details_attributes: [
          {
            value: "http://github.com/jon"
          }
        ],
        phone_contact_details_attributes: [
          {
            value: "978353499453"
          }
        ]
      }

      @customer_params_2 = {
        first_name: "Sam",
        customer_detail_attributes: {
          language: "High Valyrian",
          time_zone: "Eastern Time (US & Canada)",
          about: "About sam"
        },
        email_contact_details_attributes: [
          {
            value: "sam@example.com",
            primary: "true"
          },
          {
            value: "sam@gmail.com",
            primary: "false"
          }
        ],
        link_contact_details_attributes: [
          {
            value: "http://github.com/sam"
          }
        ],
        phone_contact_details_attributes: [
          {
            value: "978353499411"
          }
        ]
      }

      Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params_1
      ).process

      Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params_2
      ).process

      @customer1 = find_customer_by_primary_email("jon@example.com")
      @customer2 = find_customer_by_primary_email("sam@example.com")
    end

    def create_tickets_with_description_and_comments(customer)
      @ticket_1 = create :ticket, status: "open", subject: "Issue - Ticket 1", organization: @organization,
        requester: customer, created_at: 3.hours.ago
      @ticket_2 = create :ticket, status: "open", subject: "Issue - Ticket 2", organization: @organization,
        requester: customer, created_at: 2.hours.ago
      @ticket_3 = create :ticket, status: "open", subject: "Issue - Ticket 3", organization: @organization,
        requester: customer, created_at: 1.hours.ago
      create :comment, :description, ticket: @ticket_1, info: "Ticket 1 description", created_at: 3.hours.ago,
        author: customer
      create :comment, :description, ticket: @ticket_2, info: "Ticket 2 description", created_at: 2.hours.ago,
        author: customer
      create :comment, :description, ticket: @ticket_3, info: "Ticket 3 description", created_at: 1.hours.ago,
        author: customer

      create :comment, :reply, ticket: @ticket_1, info: "Ticket 1 comment 1", author: customer
      create :comment, :reply, ticket: @ticket_1, info: "Ticket 1 comment 2", author: customer

      create :comment, :reply, ticket: @ticket_2, info: "Ticket 2 comment 1", author: customer
      create :comment, :note, ticket: @ticket_2, info: "Ticket 2 note 1", author: customer

      create :comment, :note, ticket: @ticket_3, info: "Ticket 3 note 1", author: customer
      create :comment, :note, ticket: @ticket_3, info: "Ticket 3 note 2", author: customer
    end

    def create_customer_notes
      create(:note, user: @customer1, agent_id: @user.id)
      create(:note, user: @customer2, agent_id: @user.id)
    end

    def create_customer_tags
      @tag1 = create :customer_tag, organization: @organization
      @tag2 = create :customer_tag, organization: @organization
      @tag3 = create :customer_tag, organization: @organization
    end

    def create_tickets_for_customers
      create_tickets_with_description_and_comments(@customer1)
      create_tickets_with_description_and_comments(@customer2)
    end

    def create_customer_1_taggings
      Tagging.create(tag_id: @tag1.id, taggable_type: "CustomerDetail", taggable_id: @customer1.customer_detail.id)
      Tagging.create(tag_id: @tag2.id, taggable_type: "CustomerDetail", taggable_id: @customer1.customer_detail.id)
    end

    def create_customer_2_taggings
      Tagging.create(tag_id: @tag2.id, taggable_type: "CustomerDetail", taggable_id: @customer2.customer_detail.id)
      Tagging.create(tag_id: @tag3.id, taggable_type: "CustomerDetail", taggable_id: @customer2.customer_detail.id)
    end

    def find_customer_by_primary_email(email)
      User.find_by_email(email)
    end

    def check_customer_tags
      @required_tags << @tag1.name
      @required_tags << @tag2.name
      @required_tags << @tag3.name

      @customer1.customer_detail.tags.reload.each do |tag|
        @tags_after_running_merge_service << tag.name
      end

      if @required_tags == @tags_after_running_merge_service
        true
      else
        false
      end
    end
end
