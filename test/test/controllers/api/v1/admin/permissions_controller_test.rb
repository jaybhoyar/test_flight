# frozen_string_literal: true

require "test_helper"

class Api::V1::Admin::PermissionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    sign_in @user

    @desk_permissions = create(:permission)
    host! test_domain(@organization.subdomain)
  end

  def test_index_success
    get api_v1_admin_permissions_url, headers: headers(@user)

    assert_response :ok

    assert_equal 1, json_body["permissions"].count
    assert_equal ["category", "description", "id", "name", "sequence"], json_body["permissions"].first.keys.sort
  end
end
