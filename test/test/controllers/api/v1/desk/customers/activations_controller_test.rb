# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Customers::ActivationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user_with_admin_role
    @organization = @user.organization

    sign_in @user

    host! test_domain(@organization.subdomain)

    @view_permission = Permission.find_or_create_by(name: "customer.view_customer_details", category: "Customer")
    @manage_permission = Permission.find_or_create_by(name: "customer.manage_customer_details", category: "Customer")
    role = create :organization_role, permissions: [@view_permission, @manage_permission]
    @user.update(role:)
  end

  def test_block_single_customer_success
    customer = create :user, organization: @organization, role: nil

    payload = {
      customer: {
        id: customer.id,
        status: "block"
      }
    }

    assert_difference "Activity.count" do
      post api_v1_desk_customers_activations_url, params: payload, headers: headers(@user)
    end

    assert_response :ok

    assert customer.reload.blocked?
  end

  def test_that_activation_is_not_changed_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    customer_one = create :user, organization: @organization, role: nil

    payload = {
      customer: {
        id: customer_one.id,
        status: "block"
      }
    }

    post api_v1_desk_customers_activations_url, params: payload, headers: headers(@user)

    assert_response :forbidden
  end

  def test_activate_single_customer_success
    customer = create :user, organization: @organization, role: nil, blocked_at: Time.current
    assert customer.blocked?

    payload = {
      customer: {
        id: customer.id,
        status: "unblock"
      }
    }

    assert_difference "Activity.count" do
      post api_v1_desk_customers_activations_url, params: payload, headers: headers(@user)
    end

    assert_response :ok
    assert_not customer.reload.blocked?
  end

  def test_block_multiple_customers_success
    customer_one = create :user, organization: @organization, role: nil
    customer_two = create :user, organization: @organization, role: nil

    payload = {
      customer: {
        ids: [customer_one.id, customer_two.id],
        status: "block"
      }
    }

    assert_difference "Activity.count", 2 do
      patch update_multiple_api_v1_desk_customers_activations_url, params: payload, headers: headers(@user)
    end

    assert_response :ok

    assert customer_one.reload.blocked?
    assert customer_two.reload.blocked?
  end

  def test_unblock_multiple_customers_success
    customer_one = create :user, organization: @organization, role: nil, blocked_at: Time.current
    customer_two = create :user, organization: @organization, role: nil, blocked_at: Time.current

    payload = {
      customer: {
        ids: [customer_one.id, customer_two.id],
        status: "unblock"
      }
    }

    assert customer_one.blocked?
    assert customer_two.blocked?

    assert_difference "Activity.count", 2 do
      patch update_multiple_api_v1_desk_customers_activations_url, params: payload, headers: headers(@user)
    end
    assert_response :ok

    assert_not customer_one.reload.blocked?
    assert_not customer_two.reload.blocked?
  end

  def test_that_multiple_activation_doesnt_work_without_permissions
    role = create :organization_role, permissions: [@view_permission]
    @user.update(role:)

    customer_one = create :user, organization: @organization, role: nil, blocked_at: Time.current
    customer_two = create :user, organization: @organization, role: nil, blocked_at: Time.current

    payload = {
      customer: {
        ids: [customer_one.id, customer_two.id],
        status: "unblock"
      }
    }

    patch update_multiple_api_v1_desk_customers_activations_url, params: payload, headers: headers(@user)

    assert_response :forbidden
  end
end
