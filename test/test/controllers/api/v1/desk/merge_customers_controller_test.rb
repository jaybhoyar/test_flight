# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::MergeCustomersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    sign_in @user

    create_multiple_customers
    create_tickets_for_customers
    create_customer_notes
    host! test_domain(@organization.subdomain)
  end

  def test_customers_are_merged
    params = {
      primary_customer_id: @customer1.id,
      secondary_customer_ids: [@customer2.id]
    }

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

    post api_v1_desk_merge_customers_path(params), headers: headers(@user)

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

    assert_nil @customer2.customer_detail

    assert_equal 1, User.where(id: @customer1.id).count
    assert_equal 0, User.where(id: @customer2.id).count
  end

  def test_error_is_returned_when_secondary_customer_ids_empty
    params = {
      primary_customer_id: @customer1.id,
      secondary_customer_ids: []
    }

    post api_v1_desk_merge_customers_path(params), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["error"], "Atleast one secondary customer required."
  end

  def test_service_fails_when_primary_customer_is_invalid
    params = {
      primary_customer_id: "111",
      secondary_customer_ids: [@customer2.id]
    }

    post api_v1_desk_merge_customers_path(params), headers: headers(@user)

    assert_response :not_found
    assert_includes json_body["error"], "Could not find required primary customer."
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
            value: "jon@neetodesk.com",
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
            value: "sam@neetodesk.com",
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

    def create_tickets_for_customers
      create_tickets_with_description_and_comments(@customer1)
      create_tickets_with_description_and_comments(@customer2)
    end

    def find_customer_by_primary_email(email)
      ::User.find_by_email(email)
    end
end
