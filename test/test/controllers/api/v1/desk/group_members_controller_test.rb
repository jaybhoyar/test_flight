# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::GroupMembersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization
    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_index_success
    get api_v1_desk_members_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["group_members"].size
  end
end
