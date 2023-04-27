# frozen_string_literal: true

require "test_helper"

class Desk::Organizations::Users::FilterServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user, :admin, available_for_desk: false, deactivated_at: DateTime.current)
    @organization = @user.organization
  end

  def test_agent_filter_without_filter_params
    create(:user, :agent, organization: @organization)

    users = users_filter_service(all_users, {})
    assert_equal 1, users.count
  end

  def test_status_filter
    create(:user, organization: @organization)

    filter_params = { status: "active" }

    users = users_filter_service(all_users, filter_params)
    assert_equal 1, users.count
  end

  def test_index_with_roles_filter
    user_1 = create(:user, :agent, organization: @organization)
    user_2 = create(:user, :agent, organization: @organization)

    filter_params = { role_ids: [ user_1.organization_role_id ] }

    users = users_filter_service(all_users, filter_params)
    assert_equal 2, users.count
  end

  def test_index_with_available_for_desk_filter
    user_2 = create(:user, available_for_desk: true, organization: @organization)

    filter_params = { available_for_desk: "true" }
    users = users_filter_service(all_users, filter_params)
    assert_equal 1, users.count
  end

  def test_index_with_groups_filters
    user_1 = create(:user, organization: @organization)
    group_1 = create(:group, organization: @organization)
    group_2 = create(:group, organization: @organization)
    create(:group_member, user: @user, group: group_1)
    create(:group_member, user: user_1, group: group_2)

    filter_params = { group_ids: [ group_2.id ] }

    users = users_filter_service([@user, user_1], filter_params)
    assert_equal 1, users.count
  end

  private

    def all_users
      @organization.users
    end

    def users_filter_service(users, filter_params)
      Desk::Organizations::Users::FilterService.new(all_users, filter_params).process
    end
end
