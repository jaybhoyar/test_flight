# frozen_string_literal: true

require "test_helper"

class Api::V1::Reports::Desk::TicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    travel_to Time.zone.parse("2020-04-16 20:52:13")

    @organization = create :organization
    @user = create :user, organization: @organization

    permission = Permission.find_or_create_by(name: "reports.view_reports", category: "Reports")
    role = create :organization_role, organization: @organization, permissions: [permission]
    @user.update(role:)

    host! "#{@organization.subdomain}.lvh.me:3000"
  end

  def teardown
    travel_back
  end

  test "index_without_permissions" do
    @user.update(role: nil)

    get api_v1_reports_desk_tickets_url
    assert_response 401
  end

  test "index_with_authentication" do
    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    get api_v1_reports_desk_tickets_url(date_range_params), headers: headers(@user)
    assert_response 200
  end

  test "index_with_missing_parameters" do
    date_range_params = { date_range: { type: "predefined", name: "my_last_week" } }
    get api_v1_reports_desk_tickets_url(date_range_params), headers: headers(@user)
    assert_response 400
    assert_not_empty json_body["errors"]
  end

  test "index_with_predefined_date_range" do
    # Previous period
    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-01 3PM", "new")
    status_change!(ticket, "2020-04-02 1PM", "resolved")
    status_change!(ticket, "2020-04-03 11AM", "closed")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-03-31 3PM", "new")
    status_change!(ticket, "2020-04-03 1PM", "resolved")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-03-31 3PM", "new")
    status_change!(ticket, "2020-04-05 1PM", "closed")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-03-02 3PM", "new")
    status_change!(ticket, "2020-04-03 1PM", "closed")

    # Present period
    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-07 3PM", "new")
    status_change!(ticket, "2020-04-09 1PM", "resolved")
    status_change!(ticket, "2020-04-10 11AM", "closed")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-03-07 3PM", "new")
    status_change!(ticket, "2020-04-09 11AM", "closed")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-06 3PM", "new")
    status_change!(ticket, "2020-04-12 11AM", "paused")

    travel_to Time.zone.parse("2020-04-16")

    date_range_params = { date_range: { type: "predefined", name: "last_week" } }
    get api_v1_reports_desk_tickets_url(date_range_params), headers: headers(@user)
    assert_response 200

    assert_includes json_body["ticket_statuses"],
      { "name" => "closed", "value" => { "present" => 2, "previous" => 3, "change_percentage" => -33.33 } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "resolved", "value" => { "present" => 1, "previous" => 2, "change_percentage" => -50.0 } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "paused", "value" => { "present" => 1, "previous" => nil, "change_percentage" => nil } }
  end

  test "index_with_custom_date_range" do
    # Previous period
    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-01 3PM", "new")
    status_change!(ticket, "2020-04-02 3PM", "resolved")
    status_change!(ticket, "2020-04-03 3PM", "closed")

    # Present period
    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-07 3PM", "new")
    status_change!(ticket, "2020-04-09 1PM", "resolved")
    status_change!(ticket, "2020-04-10 11AM", "closed")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-03-07 3PM", "new")
    status_change!(ticket, "2020-04-09 11AM", "closed")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-07 3PM", "new")
    status_change!(ticket, "2020-04-12 11AM", "paused")

    date_range_params = { date_range: { type: "custom", from: "2020-04-07", to: "2020-04-16" } }
    get api_v1_reports_desk_tickets_url(date_range_params), headers: headers(@user)
    assert_response 200

    assert_includes json_body["ticket_statuses"],
      { "name" => "resolved", "value" => { "present" => 1, "previous" => 1, "change_percentage" => 0.0 } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "closed", "value" => { "present" => 2, "previous" => 1, "change_percentage" => 100.0 } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "paused", "value" => { "present" => 1, "previous" => nil, "change_percentage" => nil } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "new", "value" => { "present" => 2, "previous" => 1, "change_percentage" => 100.0 } }
  end

  test "with_agent_ids" do
    ticket1 = create(:ticket, organization: @organization, agent: create(:user))
    status_change!(ticket1, "2020-04-07 3PM", "new")
    status_change!(ticket1, "2020-04-09 1PM", "resolved")
    status_change!(ticket1, "2020-04-10 11AM", "closed")

    ticket2 = create(:ticket, organization: @organization, agent: ticket1.agent)
    status_change!(ticket2, "2020-04-08 3PM", "new")
    status_change!(ticket2, "2020-04-09 11AM", "closed")

    ticket3 = create(:ticket, organization: @organization, agent: create(:user))
    status_change!(ticket3, "2020-04-07 3PM", "new")
    status_change!(ticket3, "2020-04-12 11AM", "paused")

    params = { assignee: { type: "agent", ids: [ticket1.agent_id, ticket2.agent_id] } }
    date_range_params = { date_range: { type: "custom", from: "2020-04-07", to: "2020-04-16" } }
    params.merge!(date_range_params)

    get api_v1_reports_desk_tickets_url(params), headers: headers(@user)
    assert_response 200

    assert_includes json_body["ticket_statuses"],
      { "name" => "resolved", "value" => { "present" => 1, "previous" => nil, "change_percentage" => nil } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "closed", "value" => { "present" => 2, "previous" => nil, "change_percentage" => nil } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "new", "value" => { "present" => 2, "previous" => nil, "change_percentage" => nil } }
  end

  test "with_group_ids" do
    ticket1 = create(:ticket, organization: @organization, group: create(:group))
    status_change!(ticket1, "2020-04-07 3PM", "new")
    status_change!(ticket1, "2020-04-09 1PM", "resolved")
    status_change!(ticket1, "2020-04-10 11AM", "closed")

    ticket2 = create(:ticket, organization: @organization, group: ticket1.group)
    status_change!(ticket2, "2020-04-08 3PM", "new")
    status_change!(ticket2, "2020-04-09 11AM", "closed")

    ticket3 = create(:ticket, organization: @organization, group: create(:group))
    status_change!(ticket3, "2020-04-07 3PM", "new")
    status_change!(ticket3, "2020-04-12 11AM", "paused")

    params = { assignee: { type: "group", ids: [ticket1.group_id] } }
    date_range_params = { date_range: { type: "custom", from: "2020-04-07", to: "2020-04-16" } }
    params.merge!(date_range_params)

    get api_v1_reports_desk_tickets_url(params), headers: headers(@user)
    assert_response 200

    assert_includes json_body["ticket_statuses"],
      { "name" => "resolved", "value" => { "present" => 1, "previous" => nil, "change_percentage" => nil } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "closed", "value" => { "present" => 2, "previous" => nil, "change_percentage" => nil } }
    assert_includes json_body["ticket_statuses"],
      { "name" => "new", "value" => { "present" => 2, "previous" => nil, "change_percentage" => nil } }
  end

  test "time_series" do
    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-07 3PM", "new")
    status_change!(ticket, "2020-04-09 1PM", "resolved")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-03-07 3PM", "new")
    status_change!(ticket, "2020-04-09 11AM", "open")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-07 3PM", "new")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-08 3PM", "new")
    status_change!(ticket, "2020-04-18 11AM", "resolved")

    ticket = create(:ticket, organization: @organization)
    status_change!(ticket, "2020-04-09 3PM", "new")
    status_change!(ticket, "2020-04-09 11AM", "resolved")

    # Create data for other organization (Should not be loaded)
    organization_2 = create :organization
    other_ticket = create(:ticket, organization: organization_2)
    status_change!(other_ticket, "2020-04-08 3PM", "new")
    status_change!(other_ticket, "2020-04-18 11AM", "resolved")

    other_ticket = create(:ticket, organization: organization_2)
    status_change!(other_ticket, "2020-04-09 3PM", "new")
    status_change!(other_ticket, "2020-04-09 11AM", "resolved")

    date_range_params = { date_range: { type: "custom", from: "2020-04-05", to: "2020-04-10" } }
    get time_series_api_v1_reports_desk_tickets_url(date_range_params), headers: headers(@user)
    assert_response 200

    expected_dates = ["2020-04-05", "2020-04-06", "2020-04-07", "2020-04-08", "2020-04-09", "2020-04-10"]
    assert_equal expected_dates, json_body["dates"]
    assert_equal 2, json_body["data"].count

    assert_includes json_body["data"], { "name" => "new", "values" => [0, 0, 2, 1, 1, 0] }
    assert_includes json_body["data"], { "name" => "resolved", "values" => [0, 0, 0, 0, 2, 0] }
  end

  private

    def status_change!(ticket, time_string, status)
      create :desk_ticket_status_change, ticket:, created_at: Time.zone.parse(time_string), status:
    end
end
