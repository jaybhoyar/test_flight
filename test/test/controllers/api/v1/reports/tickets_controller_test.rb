# frozen_string_literal: true

require "test_helper"

class Api::V1::Reports::Desk::TicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    sign_in(@user)

    host! "#{@organization.subdomain}.lvh.me:3000"

    @view_permission = Permission.find_or_create_by(name: "reports.view_reports", category: "Reports")
    @manage_permission = Permission.find_or_create_by(name: "reports.manage_reports", category: "Reports")
    role = create :organization_role, permissions: [@view_permission, @manage_permission]
    @user.update(role:)
  end

  def test_that_index_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    date_range_params = { date_range: { type: "custom", from: "2020-04-05", to: "2020-04-11" } }
    get api_v1_reports_desk_tickets_url(date_range_params), headers: headers(@user)

    assert_response :forbidden
  end
end
