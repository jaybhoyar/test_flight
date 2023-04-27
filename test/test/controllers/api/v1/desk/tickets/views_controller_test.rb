# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::Tickets::ViewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    @user = create :user, :agent, organization: @organization

    User.current = @user
    sign_in(@user)
    host! test_domain(@organization.subdomain)
  end

  def test_that_view_is_created
    assert_difference ["View::Rule.count", "Desk::Core::Condition.count", "View.count"], 1 do
      post api_v1_desk_views_url(@organization.api_key, view_params), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "View has been successfully added.", json_body["notice"]
  end

  def test_that_view_is_not_created_with_same_title_by_same_user
    view = create :view, title: "All Open Tickets", organization: @organization
    view.creator = @user
    view.save!

    assert_no_difference ["View::Rule.count", "Desk::Core::Condition.count", "View.count"], 1 do
      post api_v1_desk_views_url(@organization.api_key, view_params), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name is already taken."
  end

  def test_that_same_title_view_can_be_created_by_other_users
    user_2 = create :user, :agent

    view = create :view, title: "All Open Tickets", organization: @organization
    view.creator = user_2
    view.save!

    assert_difference ["View::Rule.count", "Desk::Core::Condition.count", "View.count"], 1 do
      post api_v1_desk_views_url(@organization.api_key, view_params), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "View has been successfully added.", json_body["notice"]
  end

  def test_that_view_is_not_created_with_invalid_title
    payload = view_params
    payload[:view][:title] = nil

    assert_no_difference ["View::Rule.count", "View.count"] do
      post api_v1_desk_views_url(@organization.api_key, payload), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Name can't be blank"], json_body["errors"]
  end

  def test_that_view_is_not_created_with_invalid_rules
    payload = view_params
    payload[:view][:rule_attributes] = nil

    assert_no_difference "View::Rule.count" do
      post api_v1_desk_views_url(@organization.api_key, payload), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Rule can't be blank"], json_body["errors"]
  end

  def test_that_view_is_not_created_with_invalid_visibility
    payload = view_params
    payload[:view][:record_visibility_attributes][:visibility] = nil

    assert_no_difference ["View::Rule.count", "View.count"] do
      post api_v1_desk_views_url(@organization.api_key, payload), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_equal ["Record visibility visibility can't be blank"], json_body["errors"]
  end

  def test_that_view_details_are_showned
    view = create :view, title: "Open Tickets", organization: @organization
    view.creator = @user
    view.save!

    get api_v1_desk_view_url(view), headers: headers(@user)
    assert_response :ok
    assert_not_nil json_body["view"]
    assert_equal view.id, json_body["view"]["id"]
    assert_equal 0, json_body["view"]["count"]
    assert_equal 1, json_body["view"]["conditions"].length
  end

  def test_that_view_details_are_not_showned_to_non_creator
    view = create :view, title: "Open Tickets", organization: @organization
    view.creator = create :user, organization: @organization
    view.save!

    get api_v1_desk_view_url(view), headers: headers(@user)

    assert_response :forbidden
    assert_equal "Access Denied", json_body["error"]
  end

  def test_that_view_is_updated
    view = create :view, title: "My Tickets", organization: @organization
    view.creator = @user
    view.save!

    payload = {
      view: {
        title: "All Open Tickets",
        description: "All open tickets",
        record_visibility_attributes: {
          id: view.record_visibility.id,
          visibility: "myself"
        },
        rule_attributes: {
          id: view.rule.id,
          name: "open Tickets",
          description: "All open tickets",
          conditions_attributes: [
            {
              id: view.rule.conditions.first.id,
              join_type: "and_operator",
              field: "status",
              verb: "is",
              value: "open"
            }
          ]
        }
      }
    }
    assert_no_difference ["View::Rule.count", "Desk::Core::Condition.count", "View.count"] do
      put api_v1_desk_view_url(view, payload), headers: headers(@user)
    end
    assert_response :ok
    assert_equal "View has been successfully updated.", json_body["notice"]
    view.reload
    assert_equal "All Open Tickets", view.title
    assert_equal "open Tickets", view.rule.name
    assert_equal "open", view.rule.conditions.first.value
  end

  def test_that_view_is_not_updated_by_non_creator
    view = create :view, title: "My Tickets", organization: @organization
    view.creator = create :user, organization: @organization
    view.save!

    payload = {
      view: {
        title: "All Open Tickets",
        description: "All open tickets",
        record_visibility_attributes: {
          id: view.record_visibility.id,
          visibility: "myself"
        },
        rule_attributes: {
          id: view.rule.id,
          name: "open Tickets",
          description: "All open tickets",
          conditions_attributes: [
            {
              id: view.rule.conditions.first.id,
              join_type: "and_operator",
              field: "status",
              verb: "is",
              value: "open"
            }
          ]
        }
      }
    }

    put api_v1_desk_view_url(view, payload), headers: headers(@user)

    assert_response :forbidden
    assert_equal "Access Denied", json_body["error"]
  end

  def test_that_conditions_are_updated_while_updating_the_rule
    view = create :view, title: "All Open Tickets", organization: @organization
    view.creator = @user
    view.save!

    payload = {
      view: {
        title: "All Tickets",
        description: "All tickets",
        record_visibility_attributes: {
          id: view.record_visibility.id,
          visibility: "myself"
        },
        rule_attributes: {
          id: view.rule.id,
          name: "all Tickets",
          description: "All tickets",
          conditions_attributes: [
            {
              id: view.rule.conditions.first.id,
              _destroy: true
            },
            {
              id: nil,
              join_type: "and_operator",
              field: "status",
              verb: "is",
              value: "open"
            }
          ]
        }
      }
    }

    assert_no_difference ["View::Rule.count", "View.count"] do
      put api_v1_desk_view_url(view, payload), headers: headers(@user)
    end

    assert_response :ok
    view.reload
    assert_equal "All Tickets", view.title
    assert_equal 1, view.rule.conditions.count
    assert_equal "status", view.rule.conditions.first.field
  end

  def test_that_view_is_not_updated_with_invalid_data
    view = create :view, title: "All Open Tickets", organization: @organization
    view.creator = @user
    view.save!

    payload = {
      view: {
        title: "All Tickets",
        description: nil,
        record_visibility_attributes: {
          id: view.record_visibility.id,
          visibility: nil
        },
        rule_attributes: {
          id: view.rule.id,
          name: "all Tickets",
          description: "All tickets",
          conditions_attributes: [
            {
              id: view.rule.conditions.first.id,
              join_type: "and_operator",
              field: "status",
              verb: "is",
              value: nil
            },
          ]
        }
      }
    }

    put api_v1_desk_view_url(view, payload), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Rule conditions value is required."
    assert_includes json_body["errors"], "Rule is invalid"
    assert_includes json_body["errors"], "Record visibility visibility can't be blank"
  end

  def test_that_record_visibility_are_updated_while_updating_the_view
    view = create :view, title: "open Tickets", organization: @organization
    view.creator = @user
    view.save!

    payload = {
      view: {
        title: "All High Open Tickets",
        description: "All open tickets with high Priority",
        record_visibility_attributes: {
          id: view.record_visibility.id,
          visibility: "all_agents"
        },
        rule_attributes: {
          id: view.rule.id,
          name: "open High Tickets",
          description: "All open tickets",
          conditions_attributes: [
            {
              id: view.rule.conditions.first.id,
              join_type: "and_operator",
              field: "status",
              verb: "is",
              value: "open"
            }
          ]
        }
      }
    }

    assert_no_difference ["View::Rule.count", "View.count", "RecordVisibility.count"] do
      put api_v1_desk_view_url(view, payload), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "myself", view.record_visibility.visibility
    old_id = view.record_visibility.id
    view.reload
    assert_equal old_id, view.record_visibility.id
    assert_equal "all_agents", view.record_visibility.visibility
  end

  def test_that_multiple_views_are_updated_successfully
    create_multiple_views

    assert_equal 5, views.where(status: "active").count
    assert_equal 0, views.where(status: "inactive").count

    params = create_multiple_views_updation_params(views, "inactive")
    patch update_multiple_api_v1_desk_views_url(params), headers: headers(@user)

    assert_response :ok
    assert_equal "Views have been successfully deactivated.", json_body["notice"]

    assert_equal 0, views.where(status: "active").count
    assert_equal 5, views.where(status: "inactive").count
  end

  def test_that_multiple_views_are_not_updated_by_non_creator
    view = create :view, title: "Open Tickets", organization: @organization
    view.creator = create :user, organization: @organization
    view.save!

    params = create_multiple_views_updation_params([view], "inactive")
    patch update_multiple_api_v1_desk_views_url(params), headers: headers(@user)

    assert_response :forbidden
    assert_equal "Access Denied", json_body["error"]
  end

  def test_views_index_success
    other_agent = create :user_with_agent_role, organization: @organization
    sign_in(other_agent)

    payload = {
      view: {
        title: "Open Tickets",
        description: "Open Tickets",
        record_visibility_attributes: {
          visibility: "all_agents"
        },
        rule_attributes: {
          name: "Closed Tickets",
          description: "Closed Tickets",
          conditions_attributes: [
            {
              join_type: "and_operator",
              field: "status",
              verb: "is",
              value: "open"
            }
          ]
        }
      }
    }
    post api_v1_desk_views_url(@organization.api_key, payload), headers: headers(other_agent)

    sign_in(@user)
    get api_v1_desk_views_url, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["views"].count
  end

  def test_that_view_is_deleted
    view = create :view, title: "My Tickets", organization: @organization
    view.creator = @user
    view.save!

    assert_difference ["@organization.views.count"], -1 do
      delete api_v1_desk_view_url(view), headers: headers(@user)
    end

    assert_response :ok
    assert_equal "View has been successfully deleted.", json_body["notice"]
  end

  def test_that_views_are_deleted
    view1 = create :view, title: "Test One", organization: @organization
    view1.creator = @user
    view1.save!
    view2 = create :view, title: "Test Two", organization: @organization
    view2.creator = @user
    view2.save!

    view_params = {
      view: {
        ids: [view1.id, view2.id]
      }
    }

    assert_difference ["@organization.views.count"], -2 do
      delete destroy_multiple_api_v1_desk_views_url(view_params), headers: headers(@user)
    end
    assert_response :ok
    assert_equal "Views have been successfully deleted", json_body["notice"]
  end

  private

    def view_params
      {
        view: {
          title: "All Open Tickets",
          description: "All open tickets",
          record_visibility_attributes: {
            visibility: "myself"
          },
          rule_attributes: {
            name: "open Tickets",
            description: "All open tickets",
            conditions_attributes: [
              {
                join_type: "and_operator",
                field: "status",
                verb: "is",
                value: "open"
              }
            ]
          }
        }
      }
    end

    def create_multiple_views
      5.times do
        view = create(:view, title: Faker::Lorem.sentence, organization: @organization)
        view.creator = @user
        view.save!
      end
    end

    def views
      @organization.views.all
    end

    def create_multiple_views_updation_params(views, status)
      {
        view: {
          ids: views.pluck(:id),
          status:
        }
      }
    end
end
