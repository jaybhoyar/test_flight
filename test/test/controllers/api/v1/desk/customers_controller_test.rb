# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::CustomersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create(:organization)
    @user = create(:user_with_agent_role, organization: @organization)
    @customer = create(:user, organization: @organization, role: nil)
    @customer_tag = create(:customer_tag, name: "VIP", organization: @organization)
    @company = create(:company, name: "BigBinary", organization: @organization)
    @primary_email_contact_detail = @customer.email_contact_details.first

    sign_in(@user)

    host! test_domain(@organization.subdomain)

    @view_permission = Permission.find_or_create_by(name: "customer.view_customer_details", category: "Customer")
    @manage_permission = Permission.find_or_create_by(name: "customer.manage_customer_details", category: "Customer")
    role = create :organization_role, permissions: [@view_permission, @manage_permission]
    @user.update(role:)
  end

  def test_index_success
    customer_params = {
      customer: {
        page_index: 1,
        page_size: 30,
        column: "first_name",
        direction: "desc"
      }
    }

    get api_v1_desk_customers_url, params: customer_params,
      headers: headers(@user)

    default_sort = @organization.users.all.order(first_name: :desc)

    assert_response :ok
    assert_equal default_sort.last.first_name, default_sort.reverse.first.first_name
    assert_equal json_body["total_count"], json_body["customers"].size
  end

  def test_index_page_works_without_pagination_params
    customer_params = {
      customer: {
        column: "first_name",
        direction: "asc"
      }
    }

    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    default_sort = @organization.users.all.order(first_name: :asc)

    assert_response :ok
    assert_equal default_sort.last.first_name, default_sort.reverse.first.first_name
    assert_equal json_body["total_count"], json_body["customers"].size
  end

  def test_index_page_works_with_sorting_for_created_at
    create_multiple_customers
    customer_params = {
      customer: {
        page_index: 1,
        page_size: 30,
        column: "first_name",
        direction: "desc"
      }
    }

    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    sort_with_created_at_asc = customers.order(created_at: :asc)
    sort_with_created_at_desc = customers.order(created_at: :desc)

    assert_response :ok
    assert_equal customers.count, sort_with_created_at_asc.count
    assert_equal customers.count, sort_with_created_at_desc.count
    assert_equal json_body["total_count"], json_body["customers"].size
  end

  def test_index_page_work_with_sorting_for_last_modified
    create_multiple_customers
    customer_params = {
      customer: {
        page_index: 1,
        page_size: 30,
        column: "updated_at",
        direction: "desc"
      }
    }

    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    sort_with_last_modified_asc = customers.order(updated_at: :asc)
    sort_with_last_modified_desc = customers.order(updated_at: :desc)

    assert_response :ok
    assert_equal customers.count, sort_with_last_modified_asc.count
    assert_equal customers.count, sort_with_last_modified_desc.count
    assert_equal json_body["total_count"], json_body["customers"].size
  end

  def test_index_page_work_with_sorting_for_status
    create_multiple_customers
    customer_params = {
      customer: {
        page_index: 1,
        page_size: 30,
        column: "status",
        direction: "desc"
      }
    }

    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    sort_with_status_asc = customers.order(status: :asc)
    sort_with_status_desc = customers.order(status: :desc)

    assert_response :ok
    assert_equal customers.count, sort_with_status_asc.count
    assert_equal customers.count, sort_with_status_desc.count
    assert_equal json_body["total_count"], json_body["customers"].size
  end

  def test_index_success_with_filters
    customer_params = { search_string: @customer.first_name }
    get api_v1_desk_customers_url, params: { customer: customer_params }, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["customers"].size

    customer_params = { search_string: "invalid_user_name" }
    get api_v1_desk_customers_url,
      params: { customer: customer_params },
      headers: headers(@user)

    assert_response :ok
    assert_empty json_body["customers"]
  end

  def test_index_filters_with_company
    customer_params = { filters: { company_ids: [ @company.id ] } }
    get api_v1_desk_customers_url, params: { customer: customer_params }, headers: headers(@user)

    assert_response :ok
    assert_equal json_body["total_count"], json_body["customers"].size
  end

  def test_show_success
    @customer.create_customer_detail()
    @customer.reload.customer_detail.update!(tags: [ @customer_tag ])
    assert_equal 1, @customer.customer_detail.tags.count

    get api_v1_desk_customer_url(@customer), headers: headers(@user)

    assert_response :ok
    assert_equal @customer.id, json_body["customer"]["id"]
    assert_equal @customer.first_name, json_body["customer"]["first_name"]
    assert_equal @customer.last_name, json_body["customer"]["last_name"]
    assert_equal [
      "activities",
      "company_id",
      "customer_detail_attributes",
      "email",
      "email_contact_details_attributes",
      "first_name",
      "id",
      "is_access_locked",
      "is_blocked",
      "is_deactivated",
      "last_name",
      "link_contact_details_attributes",
      "name",
      "organization_id",
      "phone_contact_details_attributes",
      "status"
    ], json_body["customer"].keys.sort

    assert_equal 1, json_body["customer"]["email_contact_details_attributes"].count
    assert_equal 1, json_body["customer"]["customer_detail_attributes"]["tags"].count
  end

  def test_create_failure_without_primary_email
    customer_params = valid_customer_params
    customer_params[:customer][:email_contact_details_attributes] = [
      {
        value: "admin@example.com",
        primary: false
      }
    ]

    post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["error"], "Primary email is required"
  end

  def test_create_failure_with_invalid_primary_email
    customer_params = valid_customer_params
    customer_params[:customer][:email_contact_details_attributes] = [
      {
        value: "admin",
        primary: true
      }
    ]

    post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["error"], "Email is invalid"
  end

  def test_create_success
    customer_params = valid_customer_params

    post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    customer = User.find_by_email("admin@example.com")

    assert_response :ok
    assert_equal "Admin", customer.name
    assert_equal "admin@example.com", customer.email
    assert_equal 2, customer.email_contact_details.count
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    customer_params = valid_customer_params

    post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    customer = User.find_by_email("admin@example.com")

    assert_response :forbidden
  end

  def test_that_an_existing_company_is_automatically_assigned_with_matching_domain
    create :company_domain, name: "bigbinary.com", company: @company

    customer_params = valid_customer_params
    customer_params[:customer][:email_contact_details_attributes] = [
      {
        value: "admin@bigbinary.com",
        primary: true
      }
    ]
    post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    assert_response :ok

    customer = User.find_by_email("admin@bigbinary.com")
    assert_equal "admin@bigbinary.com", customer.email
    assert_equal @company.id, customer.company.id
  end

  def test_create_success_with_multiple_emails
    customer_params = valid_customer_params
    customer_params[:customer][:email_contact_details_attributes] = [
      { value: "admin@example.com", primary: true },
      { value: "admin@spinkart.com", primary: false },
      { value: "admin@neetodesk.com", primary: false }
    ]

    assert_difference "EmailContactDetail.count", 3 do
      post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

      assert_response :ok
      assert_equal "admin@example.com", User.all.order("created_at DESC").first.email
    end
  end

  def test_create_success_with_multiple_phones
    customer_params = valid_customer_params
    customer_params[:customer][:phone_contact_details_attributes] = [
      { value: "87686846768" },
      { value: "6765753754" },
      { value: "7868663876" }
    ]

    assert_difference "PhoneContactDetail.count", 3 do
      post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

      assert_response :ok
    end
  end

  def test_create_success_with_multiple_links
    customer_params = valid_customer_params
    customer_params[:customer][:link_contact_details_attributes] = [
      { value: "http://github.com/admin" },
      { value: "http://dribbble.com/admin" },
      { value: "http://twitter.com/admin" }
    ]

    assert_difference "LinkContactDetail.count", 3 do
      post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

      assert_response :ok
    end
  end

  def test_create_success_with_customer_details
    customer_params = valid_customer_params

    post api_v1_desk_customers_url, params: customer_params, headers: headers(@user)

    assert_response :ok

    customer = User.find_by_email("admin@example.com")
    assert_equal "Admin", customer.first_name
    assert_equal "admin@example.com", customer.email
    assert_equal "Elvish", customer.customer_detail.language
    assert_equal "Eastern Time (US & Canada)", customer.customer_detail.time_zone
    assert_equal "about me", customer.customer_detail.about
  end

  def test_update_success
    update_customer_params = {
      customer: {
        first_name: "Oliver", last_name: "Smith",
        customer_detail_attributes: {
          language: "Elvish",
          time_zone: "Eastern Time (US & Canada)",
          about: "about me"
        }
      }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    @customer.reload

    assert_response :ok
    assert_equal "#{@customer.name}'s details have been updated successfully.", json_body["notice"]
    assert_equal "Oliver Smith", @customer.name
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    update_customer_params = {
      customer: {
        first_name: "Oliver", last_name: "Smith",
        customer_detail_attributes: {
          language: "Elvish",
          time_zone: "Eastern Time (US & Canada)",
          about: "about me"
        }
      }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_update_success_with_customer_details_and_tags
    update_customer_params = {
      customer: {
        customer_detail_attributes: {
          language: "Elvish",
          time_zone: "Eastern Time (US & Canada)",
          about: "about me",
          tags: [{
            id: @customer_tag.id
          }]
        }
      }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal "#{@customer.name}'s details have been updated successfully.", json_body["notice"]

    @customer.reload
    assert_equal "Elvish", @customer.customer_detail.language
    assert_equal "Eastern Time (US & Canada)", @customer.customer_detail.time_zone
    assert_equal "about me", @customer.customer_detail.about
    assert_equal 1, @customer.customer_detail.tags.count
  end

  def test_update_fails_with_validation_error_for_invalid_primary_email
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "admin",
            primary: true,
            id: @primary_email_contact_detail.id
          }
        ]
      }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Email contact details value is invalid"
  end

  def test_update_fails_without_error_for_zero_primary_emails
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "admin@example.us",
            primary: false,
            id: @primary_email_contact_detail.id
          }
        ]
      }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal @customer.email, @primary_email_contact_detail.reload.value
  end

  def test_update_with_multiple_primary_emails_saves_one_email_as_primary
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "admin@example.ca",
            primary: true
          },
          {
            value: "admin@example.nz",
            primary: true
          }
        ]
      }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :ok

    @customer.reload

    assert_equal 1, @customer.email_contact_details.where(primary: true).count
    assert_equal 2, @customer.email_contact_details.count
  end

  def test_update_password_success
    update_customer_params = {
      customer: { password: "121212" }
    }

    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal "#{@customer.name}'s details have been updated successfully.", json_body["notice"]
  end

  def test_update_success_of_primary_email_contact_details
    customer_params = {
      customer: {
        first_name: "Admin",
        email_contact_details_attributes: [
          {
            value: "admin@spinkart.us",
            primary: true,
            id: @user.email_contact_details.first.id
          }
        ]
      }
    }
    patch api_v1_desk_customer_url(@user),
      params: customer_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal "admin@spinkart.us", @user.reload.email
    assert_equal 1, @user.email_contact_details.count
    assert_equal "admin@spinkart.us", @user.email_contact_details.first.value
  end

  def test_update_failure_of_invalid_secondary_email
    secondary_email = create(:email_contact_detail, user: @customer)
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "admin",
            primary: false,
            id: secondary_email.id
          }
        ]
      }
    }
    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Email contact details value is invalid"
  end

  def test_update_failure_without_error_with_duplicate_secondary_email
    secondary_email = create(:email_contact_detail, user: @customer)
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: @primary_email_contact_detail.value,
            primary: false,
            id: secondary_email.id
          }
        ]
      }
    }
    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], " Email #{@primary_email_contact_detail.value} already exists."
  end

  def test_update_success_of_valid_secondary_email
    secondary_email = create(:email_contact_detail, user: @customer)
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "admin@spinkart.com",
            primary: false,
            id: secondary_email.id
          }
        ]
      }
    }
    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_response :ok
    assert_equal "#{@customer.name}'s details have been updated successfully.", json_body["notice"]
    assert_equal secondary_email.reload, @customer.email_contact_details.find(secondary_email.id)
  end

  def test_change_of_primary_email_to_a_new_email
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "jon@example.com",
            primary: true
          }
        ]
      }
    }

    assert_difference "EmailContactDetail.count", 1 do
      patch api_v1_desk_customer_url(@customer),
        params: update_customer_params,
        headers: headers(@user)

      assert_response :ok
      assert_equal "jon@example.com", @customer.reload.email
    end
  end

  def test_update_failure_for_duplicate_primary_email
    user = create(:user, organization: @organization, email: "oliver@spinkart.com")
    assert user.valid?

    update_customer_params = {
      customer: {
        first_name: "steve",
        email_contact_details_attributes: [
          {
            value: user.email,
            primary: true
          }
        ]
      }
    }

    assert_no_difference "EmailContactDetail.count" do
      patch api_v1_desk_customer_url(@customer),
        params: update_customer_params,
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], " Email oliver@spinkart.com already exists."

    assert_not_equal user.email, @customer.reload.email
    assert @primary_email_contact_detail.reload.primary?
    assert_equal @primary_email_contact_detail.value, @customer.email
    assert_equal 1, @customer.email_contact_details.where(primary: true).count
    assert_equal "steve", @customer.first_name
  end

  def test_update_failure_for_invalid_secondary_email
    update_customer_params = {
      customer: {
        first_name: "steve",
        email_contact_details_attributes: [
          {
            value: "oliver@spinkart.com",
            primary: true,
            id: @primary_email_contact_detail.id
          },
          {
            value: "oliver@spinkart.com",
            primary: false
          }
        ]
      }
    }

    assert_no_difference "EmailContactDetail.count" do
      patch api_v1_desk_customer_url(@customer),
        params: update_customer_params,
        headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], " Email oliver@spinkart.com already exists."

    assert @primary_email_contact_detail.reload.primary?
    assert_equal @primary_email_contact_detail.value, @customer.reload.email
    assert_equal 1, @customer.email_contact_details.count
    assert_equal "oliver@spinkart.com", @customer.email
    assert_equal "steve", @customer.first_name
  end

  def test_delete_of_secondary_email
    secondary_email = create(:email_contact_detail, user: @customer)
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: secondary_email.value,
            primary: false,
            id: secondary_email.id,
            _destroy: true
          }
        ]
      }
    }
    assert_difference "EmailContactDetail.count", -1 do
      patch api_v1_desk_customer_url(@customer),
        params: update_customer_params,
        headers: headers(@user)

      assert_response :ok
      assert_equal "#{@customer.name}'s details have been updated successfully.", json_body["notice"]
    end
  end

  def test_delete_fail_for_primary_email
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: @primary_email_contact_detail.value,
            primary: true,
            id: @primary_email_contact_detail.id,
            _destroy: true
          }
        ]
      }
    }
    assert_no_difference "EmailContactDetail.count" do
      patch api_v1_desk_customer_url(@customer),
        params: update_customer_params,
        headers: headers(@user)
    end
  end

  def test_delete_success_for_primary_email_with_a_valid_replacement
    secondary_email = create(:email_contact_detail, user: @customer)
    update_customer_params = {
      customer: {
        email_contact_details_attributes: [
          {
            value: "new@example.com",
            primary: true,
            id: secondary_email.id
          },
          {
            value: @primary_email_contact_detail.value,
            primary: false,
            id: @primary_email_contact_detail.id,
            _destroy: true
          }
        ]
      }
    }
    patch api_v1_desk_customer_url(@customer),
      params: update_customer_params,
      headers: headers(@user)

    assert_equal 1, @customer.reload.email_contact_details.count
    assert_equal "new@example.com", @customer.reload.email

    assert_raises ActiveRecord::RecordNotFound do
      assert_nil @primary_email_contact_detail.reload.id
    end
  end

  def test_customer_search_by_name
    customer = create(:user, organization: @organization, role: nil, name: "Roger Uniquename Federer")

    customer_params = { customer: { search_string: "uniquename" } }
    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    assert_response :ok
    assert_equal 1, json_body["customers"].size

    customer.update!(name: "Roger Notsounique Federer")

    customer_params = { customer: { search_string: "uniquename" } }
    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    assert_response :ok
    assert_equal 0, json_body["customers"].size

    customer_params = { customer: { search_string: "notso" } }
    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    assert_response :ok
    assert_equal 1, json_body["customers"].size
  end

  def test_customer_search_by_email
    customer = create(:user, organization: @organization, role: nil, email: "dummy_email@example.com")

    customer_params = { customer: { search_string: "dummy_email" } }
    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    assert_response :ok
    assert_equal 1, json_body["customers"].size

    customer.update!(email: "yet_another_email@mail.com")

    customer_params = { customer: { search_string: "dummy_email" } }
    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    assert_response :ok
    assert_equal 0, json_body["customers"].size

    customer_params = { customer: { search_string: "another_email" } }
    get api_v1_desk_customers_url, params: customer_params, headers: headers(@user)
    assert_response :ok
    assert_equal 1, json_body["customers"].size
  end

  def test_customers_deletion
    admin_one = create(:user, :admin, organization: @organization)
    first_customer = create(:user, role: nil, organization: @organization)
    second_customer = create(:user, role: nil, organization: @organization)

    first_customer_ticket = create :ticket,
      organization: @organization,
      requester: first_customer
    second_customer_ticket = create :ticket,
      organization: @organization,
      requester: second_customer

    create :comment, ticket: first_customer_ticket
    create :comment, ticket: second_customer_ticket

    customer_params = {
      customer: {
        ids: [first_customer.id, second_customer.id]
      }
    }
    assert_difference -> { @organization.users.count } => -2,
      -> { Ticket.count } => -2,
      -> { Comment.count } => -2 do
        delete destroy_multiple_api_v1_desk_customers_url(customer_params), headers: headers(@user)
        assert_enqueued_jobs 2
        perform_enqueued_jobs
      end

    assert_response :ok
    assert_equal "Customers have been successfully removed.", json_body["notice"]
  end

  def test_customer_deletion_when_customer_have_tickets_created_by_himself
    create(:ticket, submitter: @customer, requester: @customer, organization: @organization)

    delete api_v1_desk_customer_url(@customer), headers: headers(@user)

    assert_response :ok
  end

  private

    def valid_customer_params
      {
        customer: {
          first_name: "Admin",
          customer_detail_attributes: {
            language: "Elvish",
            time_zone: "Eastern Time (US & Canada)",
            about: "about me"
          },
          email_contact_details_attributes: [
            {
              value: "admin@example.com",
              primary: true
            },
            {
              value: "admin@spinkart.com",
              primary: false
            }
          ],
          link_contact_details_attributes: [
            {
              value: "http://github.com/admin"
            }
          ],
          phone_contact_details_attributes: [
            {
              value: "978353499453"
            }
          ]
        }
      }
    end

    def create_multiple_customers
      5.times do
        create(:user, organization: @organization, role: nil)
      end
    end

    def customers
      User.where(role: nil)
    end
end
