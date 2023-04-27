# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Customers::ContactEmailsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_admin_role)
    @organization = @user.organization
    @company = create(:company, organization: @organization)

    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @view_permission = Permission.find_or_create_by(name: "customer.view_customer_details", category: "Customer")
    @manage_permission = Permission.find_or_create_by(name: "customer.manage_customer_details", category: "Customer")
    role = create :organization_role, permissions: [@view_permission, @manage_permission]
    @user.update(role:)
  end

  def test_should_return_all_customers_with_email_contact_details
    create_customers
    get api_v1_desk_customer_contact_emails_url(@user), headers: headers(@user)
    assert_equal 2, json_body["users"].count
    assert_equal ["name", "id", "email_contact_details"], json_body["users"].first.keys
    assert_equal 1, json_body["users"].first["email_contact_details"].count
  end

  private

    def create_customers
      @customers = create_list(:user, 2, role: nil, organization: @organization)
    end
end
