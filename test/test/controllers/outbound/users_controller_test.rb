# frozen_string_literal: true

require "test_helper"

class Outbound::UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    @outbound_message = create :outbound_message

    host! test_domain(@organization.subdomain)
  end

  def test_csv_download
    sign_in @user
    get outbound_users_download_url(@outbound_message.id), params: { format: "csv" }
    assert_equal "text/csv", response.content_type
  end

  def test_download_for_unauthorized_user
    get outbound_users_download_url(@outbound_message.id), params: { format: "csv" }
    assert_response 401
  end
end
