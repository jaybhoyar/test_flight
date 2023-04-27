# frozen_string_literal: true

require "test_helper"

class Api::V1::Reports::Desk::GroupsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization

    host! "#{@organization.subdomain}.lvh.me:3000"
    @manage_permission = Permission.find_or_create_by(name: "reports.view_reports", category: "Reports")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)
  end

  def teardown
    travel_back
  end

  test "index_without_permissions" do
    role = create :organization_role
    @user.update(role:)

    get api_v1_reports_desk_groups_url
    assert_response :unauthorized
  end

  test "index_with_predefined_date_range" do
    group1 = create(:group, organization: @organization)
    agent_role = create :organization_role_agent, organization: @organization
    agent1 = create(:user, organization: @organization, role: agent_role, groups: [group1])

    group2 = create(:group, organization: @organization)
    agent2 = create(:user, organization: @organization, role: agent_role, groups: [group2])

    # Previous period
    travel_to Time.zone.parse("2020-04-02 20:00:00")
    ticket = create(:ticket, group: group1, organization: @organization)
    reply!(ticket, "2020-04-03 23:00:00", agent1) # 27.0 hours
    resolve!(ticket, "2020-04-04 20:00:00") # 48.0 hours

    travel_to Time.zone.parse("2020-04-03 10:00:00")
    ticket = create(:ticket, group: group2, organization: @organization)
    reply!(ticket, "2020-04-04 10:30:00", agent2) # 24.5 hours
    resolve!(ticket, "2020-04-05 14:00:00") # 52.0 hours

    travel_to Time.zone.parse("2020-04-01 16:00:00")
    ticket = create(:ticket, group: group1, organization: @organization)
    reply!(ticket, "2020-04-01 20:30:00", agent1) # 4.5 hours

    travel_to Time.zone.parse("2020-04-02 12:00:00")
    ticket = create(:ticket, group: group2, organization: @organization)
    reply!(ticket, "2020-04-03 16:30:00", agent2) # 28.5 hours
    resolve!(ticket, "2020-04-04 08:00:00") # 44.0 hours

    # Present period
    travel_to Time.zone.parse("2020-04-06 20:00:00")
    ticket = create(:ticket, group: group1, organization: @organization)
    reply!(ticket, "2020-04-06 23:00:00", agent1) # 3.0 hours
    resolve!(ticket, "2020-04-07 20:00:00") # 24.0 hours

    travel_to Time.zone.parse("2020-04-07 10:00:00")
    ticket = create(:ticket, group: group2, organization: @organization)
    reply!(ticket, "2020-04-07 10:30:00", agent2) # 0.5 hours
    resolve!(ticket, "2020-04-07 14:00:00") # 4.0 hours

    travel_to Time.zone.parse("2020-04-10 16:00:00")
    ticket = create(:ticket, group: group1, organization: @organization)
    reply!(ticket, "2020-04-10 18:30:00", agent1) # 2.5 hours

    travel_to Time.zone.parse("2020-04-07 12:00:00")
    ticket = create(:ticket, group: group2, organization: @organization)
    reply!(ticket, "2020-04-07 16:30:00", agent2) # 4.5 hours
    resolve!(ticket, "2020-04-08 08:00:00") # 20.0 hours

    travel_to Time.zone.parse("2020-04-16 20:52:13")
    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    get api_v1_reports_desk_groups_url(date_range_params), headers: headers(@user)
    assert_response 200
    assert_equal 2, json_body["teams"].size

    assert_includes json_body["teams"], {
      "id" => group1.id, "name" => group1.name,
      "assigned" => { "present" => 2, "previous" => 2, "change_percentage" => 0.0 },
      "first_response_time" => { "present" => 2.75, "previous" => 15.75, "change_percentage" => -82.54 },
      "resolution_time" => { "present" => 24.0, "previous" => 48.0, "change_percentage" => -50.0 },
      "resolved" => { "present" => 1, "previous" => 1, "change_percentage" => 0.0 }
    }

    assert_includes json_body["teams"], {
      "id" => group2.id, "name" => group2.name,
      "assigned" => { "present" => 2, "previous" => 2, "change_percentage" => 0.0 },
      "first_response_time" => { "present" => 2.5, "previous" => 26.5, "change_percentage" => -90.57 },
      "resolution_time" => { "present" => 12.0, "previous" => 48.0, "change_percentage" => -75.0 },
      "resolved" => { "present" => 2, "previous" => 2, "change_percentage" => 0.0 }
    }

    assert_equal(
      {
        "first_response_time" => { "present" => 2.63, "previous" => 21.13, "change_percentage" => -87.55 },
        "resolution_time" => { "present" => 18.00, "previous" => 48.0, "change_percentage" => -62.50 },
        "assigned" => { "present" => 2.0, "previous" => 2.0, "change_percentage" => 0.0 },
        "resolved" => { "present" => 1.5, "previous" => 1.5, "change_percentage" => 0.0 }
      }, json_body["summary"])
  end

  test "with_group_id" do
    group1 = create(:group, organization: @organization)
    agent_role = create :organization_role_agent, organization: @organization
    agent1 = create(:user, organization: @organization, role: agent_role, groups: [group1])

    group2 = create(:group, organization: @organization)
    agent2 = create(:user, organization: @organization, role: agent_role, groups: [group2])

    travel_to Time.zone.parse("2020-04-06 20:00:00")
    ticket1 = create(:ticket, group: group1, organization: @organization)
    reply!(ticket1, "2020-04-06 23:00:00", agent1) # 3.0 hours
    resolve!(ticket1, "2020-04-07 20:00:00") # 24.0 hours

    travel_to Time.zone.parse("2020-04-07 10:00:00")
    ticket2 = create(:ticket, group: group2, organization: @organization)
    reply!(ticket2, "2020-04-07 10:30:00", agent2) # 0.5 hours
    resolve!(ticket2, "2020-04-07 14:00:00") # 4.0 hours

    travel_to Time.zone.parse("2020-04-10 16:00:00")
    ticket3 = create(:ticket, group: group1, organization: @organization)
    reply!(ticket3, "2020-04-10 18:30:00", agent1) # 2.5 hours

    travel_to Time.zone.parse("2020-04-07 12:00:00")
    ticket4 = create(:ticket, group: group2, organization: @organization)
    reply!(ticket4, "2020-04-07 16:30:00", agent2) # 4.5 hours
    resolve!(ticket4, "2020-04-08 08:00:00") # 20.0 hours

    travel_to Time.zone.parse("2020-04-16 20:52:13")

    params = { assignee: { type: "group", ids: [group2.id] } }
    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    params.merge! date_range_params

    get api_v1_reports_desk_groups_url(params), headers: headers(@user)

    assert_response 200
    assert_equal 1, json_body["teams"].size

    assert_includes json_body["teams"], {
      "id" => group2.id, "name" => group2.name,
      "assigned" => { "present" => 2, "previous" => nil, "change_percentage" => nil },
      "first_response_time" => { "present" => 2.5, "previous" => nil, "change_percentage" => nil },
      "resolution_time" => { "present" => 12.0, "previous" => nil, "change_percentage" => nil },
      "resolved" => { "present" => 2, "previous" => nil, "change_percentage" => nil }
    }

    assert_equal(
      {
        "first_response_time" => { "present" => 2.5, "previous" => nil, "change_percentage" => nil },
        "resolution_time" => { "present" => 12.0, "previous" => nil, "change_percentage" => nil },
        "assigned" => { "present" => 2, "previous" => nil, "change_percentage" => nil },
        "resolved" => { "present" => 2, "previous" => nil, "change_percentage" => nil }
      }, json_body["summary"])
  end

  def resolve!(ticket, time_string)
    travel_to Time.zone.parse(time_string)
    ticket.update! status: "resolved"
  end

  def reply!(ticket, time_string, agent)
    travel_to Time.zone.parse(time_string)
    ticket.comments.create! info: "First response text", author: agent
  end
end
