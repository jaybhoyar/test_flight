# frozen_string_literal: true

require "test_helper"

class Api::V1::Reports::Desk::AgentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create :organization
    @agent_role = create :organization_role_agent
    @user = create(
      :user, organization: @organization,
      role: @agent_role)
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

    get api_v1_reports_desk_agents_url
    assert_response :unauthorized
  end

  test "index_with_predefined_date_range" do
    agent1 = create(:user, organization: @organization, role: @agent_role)
    agent2 = create(:user, organization: @organization, role: @agent_role)

    # Previous period
    travel_to Time.zone.parse("2020-04-01 20:00:00")
    ticket = create(:ticket, agent: agent1, organization: @organization)
    reply!(ticket, "2020-04-02 23:00:00") # 27.0 hours
    resolve!(ticket, "2020-04-04 20:00:00") # 72.0 hours

    travel_to Time.zone.parse("2020-04-02 10:00:00")
    ticket = create(:ticket, agent: agent1, organization: @organization)
    reply!(ticket, "2020-04-05 10:30:00") # 72.5 hours
    resolve!(ticket, "2020-04-06 14:00:00") # 100.0 hours

    travel_to Time.zone.parse("2020-04-03 16:00:00")
    ticket = create(:ticket, agent: agent2, organization: @organization)
    resolve!(ticket, "2020-04-04 08:00:00") # 16.0 hours

    travel_to Time.zone.parse("2020-04-02 12:00:00")
    ticket = create(:ticket, agent: agent2, organization: @organization)
    resolve!(ticket, "2020-04-04 08:00:00") # 20.0 hours

    # This period
    travel_to Time.zone.parse("2020-04-06 20:00:00")
    ticket = create(:ticket, agent: agent1, organization: @organization)
    reply!(ticket, "2020-04-06 23:00:00") # 3.0 hours
    resolve!(ticket, "2020-04-07 20:00:00") # 24.0 hours

    travel_to Time.zone.parse("2020-04-07 10:00:00")
    ticket = create(:ticket, agent: agent1, organization: @organization)
    reply!(ticket, "2020-04-07 10:30:00") # 0.5 hours
    resolve!(ticket, "2020-04-07 14:00:00") # 4.0 hours

    travel_to Time.zone.parse("2020-04-10 16:00:00")
    ticket = create(:ticket, agent: agent2, organization: @organization)
    reply!(ticket, "2020-04-10 18:30:00") # 2.5 hours

    travel_to Time.zone.parse("2020-04-07 12:00:00")
    ticket = create(:ticket, agent: agent2, organization: @organization)
    reply!(ticket, "2020-04-07 16:30:00") # 4.5 hours
    resolve!(ticket, "2020-04-08 08:00:00") # 20.0 hours

    travel_to Time.zone.parse("2020-04-16 20:52:13")
    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    get api_v1_reports_desk_agents_url(date_range_params), headers: headers(@user)
    assert_response 200
    assert_equal 2, json_body["members"].size

    assert_includes json_body["members"], {
      "id" => agent1.id, "name" => agent1.name,
      "assigned" => { "present" => 2.0, "previous" => 2.0, "change_percentage" => 0.0 },
      "first_response_time" => { "present" => 1.75, "previous" => 49.75, "change_percentage" => -96.48 },
      "resolution_time" => { "present" => 14.0, "previous" => 86.0, "change_percentage" => -83.72 },
      "resolved" => { "present" => 2.0, "previous" => 2.0, "change_percentage" => 0.0 }
    }

    assert_includes json_body["members"], {
      "id" => agent2.id, "name" => agent2.name,
      "assigned" => { "present" => 2.0, "previous" => nil, "change_percentage" => nil },
      "first_response_time" => { "present" => 3.5, "previous" => nil, "change_percentage" => nil },
      "resolution_time" => { "present" => 20.0, "previous" => nil, "change_percentage" => nil },
      "resolved" => { "present" => 1.0, "previous" => nil, "change_percentage" => nil }
    }

    assert_equal(
      {
        "first_response_time" => { "present" => 2.63, "previous" => 49.75, "change_percentage" => -94.71 },
        "resolution_time" => { "present" => 17.0, "previous" => 86.0, "change_percentage" => -80.23 },
        "assigned" => { "present" => 2.0, "previous" => 2.0, "change_percentage" => 0.0 },
        "resolved" => { "present" => 1.5, "previous" => 2.0, "change_percentage" => -25.0 }
      }, json_body["summary"])
  end

  test "with_agent_ids" do
    agent1 = create(:user, organization: @organization, role: @agent_role)
    agent2 = create(:user, organization: @organization, role: @agent_role)

    travel_to Time.zone.parse("2020-04-06 20:00:00")
    ticket1 = create(:ticket, agent: agent1, organization: @organization)
    reply!(ticket1, "2020-04-06 23:00:00") # 3.0 hours
    resolve!(ticket1, "2020-04-07 20:00:00") # 24.0 hours

    travel_to Time.zone.parse("2020-04-07 10:00:00")
    ticket2 = create(:ticket, agent: agent1, organization: @organization)
    reply!(ticket2, "2020-04-07 10:30:00") # 0.5 hours
    resolve!(ticket2, "2020-04-07 14:00:00") # 4.0 hours

    travel_to Time.zone.parse("2020-04-10 16:00:00")
    ticket3 = create(:ticket, agent: agent2, organization: @organization)
    reply!(ticket3, "2020-04-10 18:30:00") # 2.5 hours

    travel_to Time.zone.parse("2020-04-07 12:00:00")
    ticket4 = create(:ticket, agent: agent2, organization: @organization)
    reply!(ticket4, "2020-04-07 16:30:00") # 4.5 hours
    resolve!(ticket4, "2020-04-08 08:00:00") # 20.0 hours

    travel_to Time.zone.parse("2020-04-16 20:52:13")

    params = { assignee: { type: "agent", ids: [agent1.id] } }
    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    params.merge! date_range_params

    get api_v1_reports_desk_agents_url(params), headers: headers(@user)
    assert_response 200
    assert_equal 1, json_body["members"].size

    assert_includes json_body["members"], {
      "id" => agent1.id, "name" => agent1.name,
      "first_response_time" => { "present" => 1.75, "previous" => nil, "change_percentage" => nil },
      "resolution_time" => { "present" => 14.0, "previous" => nil, "change_percentage" => nil },
      "assigned" => { "present" => 2.0, "previous" => nil, "change_percentage" => nil },
      "resolved" => { "present" => 2.0, "previous" => nil, "change_percentage" => nil }
    }

    assert_equal(
      {
        "first_response_time" => { "present" => 1.75, "previous" => nil, "change_percentage" => nil },
        "resolution_time" => { "present" => 14.0, "previous" => nil, "change_percentage" => nil },
        "assigned" => { "present" => 2.0, "previous" => nil, "change_percentage" => nil },
        "resolved" => { "present" => 2.0, "previous" => nil, "change_percentage" => nil }
      }, json_body["summary"])
  end

  def resolve!(ticket, time_string)
    travel_to Time.zone.parse(time_string)
    ticket.update! status: "resolved"
  end

  def reply!(ticket, time_string)
    travel_to Time.zone.parse(time_string)
    ticket.comments.create! info: "First response text", author: ticket.agent
  end
end
