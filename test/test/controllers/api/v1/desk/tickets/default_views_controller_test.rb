# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::ViewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user_with_agent_role)
    @organization = @user.organization

    sign_in(@user)
    User.current = @user

    host! test_domain(@organization.subdomain)
  end

  def test_views_index_success_default_views
    create(:ticket, organization: @organization)
    agent = create(:user_with_agent_role, organization: @organization)
    create(:ticket, organization: @organization, agent_id: agent.id)
    create(:ticket, organization: @organization).update!(status: "spam")
    create(:ticket, organization: @organization).update!(status: "trash")
    create(:ticket, organization: @organization, status: "closed")

    get api_v1_desk_default_views_url,
      headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["views"]["default_views"]["all"]
    assert_equal 1, json_body["views"]["default_views"]["assigned"]
    assert_equal 1, json_body["views"]["default_views"]["unassigned"]
    assert_equal 1, json_body["views"]["default_views"]["spam"]
    assert_equal 1, json_body["views"]["default_views"]["trash"]
    assert_equal 1, json_body["views"]["default_views"]["closed"]
  end

  def test_only_active_views_are_visible
    view = create :view, organization: @organization, status: "inactive"
    view.creator = @user
    view.save!

    assert_not view.active?

    get api_v1_desk_default_views_url, headers: headers(@user)
    assert_response :ok
    assert_equal 0, json_body["views"]["custom_views"].count

    view.active!
    assert view.active?

    get api_v1_desk_default_views_url, headers: headers(@user)
    assert_response :ok
    assert_equal 1, json_body["views"]["custom_views"].count
  end
end
