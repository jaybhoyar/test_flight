# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::BusinessHoursControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    create(:business_hour, organization: @organization, name: Desk::BusinessHour::DEFAULT)
    @business_hour = create(:business_hour, organization: @organization)

    sign_in(@user)

    host! test_domain(@organization.subdomain)
  end

  def test_index
    params = {
      business_hour: {
        column: "name",
        direction: "asc"
      }
    }

    get api_v1_desk_business_hours_url, params: params, headers: headers(@user)
    assert_response :success
    assert_equal 2, json_body["business_hours"].size
    assert_equal "Default Business Hours", json_body["business_hours"][0]["name"]
  end

  def test_create_success
    payload = {
      business_hour: {
        name: "Billing Team",
        schedules_attributes: [
          {
            day: "Monday",
            status: "active",
            from: "09:00 AM",
            to: "05:00 PM"
          },
          {
            day: "Tuesday",
            status: "active",
            from: "09:00 AM",
            to: "05:00 PM"
          }
        ]
      }
    }

    assert_difference "Desk::BusinessHour.count" do
      post api_v1_desk_business_hours_url(payload), headers: headers(@user)
    end
    assert_response :success
  end

  def test_that_duplicate_schedule_days_are_not_accepted
    payload = {
      business_hour: {
        name: "Billing Team",
        schedules_attributes: [
          {
            day: "Monday",
            status: "active",
            from: "09:00 AM",
            to: "05:00 PM"
          },
          {
            day: "Monday",
            status: "active",
            from: "09:00 AM",
            to: "05:00 PM"
          }
        ]
      }
    }

    assert_no_difference "Desk::BusinessHour.count" do
      post api_v1_desk_business_hours_url(payload), headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Schedules cannot have duplicate days."
  end

  def test_create_failure
    business_hour_params = { business_hour: attributes_for(:business_hour, name: "") }
    post api_v1_desk_business_hours_url(business_hour_params), headers: headers(@user)
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name should not be blank"
  end

  def test_edit_success
    create(:schedule, business_hour: @business_hour)
    create(:holiday, business_hour: @business_hour)

    get edit_api_v1_desk_business_hour_url(@business_hour.id),
      headers: headers(@user)

    assert_response :ok
    assert_equal @business_hour.id, json_body["business_hour"]["id"]
    assert_equal @business_hour.name, json_body["business_hour"]["name"]
    assert_equal @business_hour.description, json_body["business_hour"]["description"]
    assert_equal @business_hour.time_zone, json_body["business_hour"]["time_zone"]

    schedule_data = @business_hour.reload.schedules.map do |schedule|
      {
        id: schedule.id,
        day: schedule.day,
        status: schedule.status,
        to: schedule.to,
        from: schedule.from
      }
    end
    assert_equal JSON.parse(schedule_data.to_json), json_body["business_hour"]["schedules"]

    holiday_data = @business_hour.holidays
    holiday_data = holiday_data.map do |holiday|
      {
        id: holiday.id,
        name: holiday.name,
        date: holiday.date
      }
    end
    assert_equal JSON.parse(holiday_data.to_json), json_body["business_hour"]["holidays"]
    assert json_body["business_hour"]["time_zones"]
  end

  def test_edit_failure
    get edit_api_v1_desk_business_hour_url(0), headers: headers(@user)
    assert_response :not_found
  end

  def test_show_success
    create(:schedule, business_hour: @business_hour)
    create(:holiday, business_hour: @business_hour)
    get api_v1_desk_business_hour_url(@business_hour.id), headers: headers(@user)

    assert_response :ok
    assert @business_hour.schedules.all? { |schedule| schedule.active? }
    assert_equal @business_hour.id, json_body["business_hour"]["id"]
    assert_equal @business_hour.name, json_body["business_hour"]["name"]
    assert_equal @business_hour.description, json_body["business_hour"]["description"]
    assert_equal @business_hour.time_zone, json_body["business_hour"]["time_zone"]

    schedule_data = @business_hour.reload.schedules.map do |schedule|
      {
        id: schedule.id,
        day: schedule.day,
        status: schedule.status,
        to: schedule.to,
        from: schedule.from
      }
    end
    assert_equal JSON.parse(schedule_data.to_json), json_body["business_hour"]["schedules"]

    holiday_data = @business_hour.holidays
    holiday_data = holiday_data.map do |holiday|
      {
        id: holiday.id,
        name: holiday.name,
        date: holiday.date
      }
    end
    assert_equal JSON.parse(holiday_data.to_json), json_body["business_hour"]["holidays"]
  end

  def test_show_failure
    get api_v1_desk_business_hour_url(
      0), headers: headers(@user)
    assert_response :not_found
  end

  def test_update_success
    schedule_id = create(:schedule, business_hour: @business_hour).id
    payload = {
      business_hour: {
        description: "India business hours",
        time_zone: "Kolkata",
        schedules_attributes: {
          schedule_id => {
            from: "1/1/2020 11:00",
            to: "1/1/2020 17:00",
            status: "active"
          }
        }
      }
    }

    patch api_v1_desk_business_hour_url(@business_hour.id),
      headers: headers(@user),
      params: payload

    assert_response :ok
    assert_equal "Business hour has been successfully updated.", json_body["notice"]
  end

  def test_update_failure
    payload = { business_hour: { name: "" } }
    patch api_v1_desk_business_hour_url(@business_hour.id),
      headers: headers(@user),
      params: payload

    assert_response :unprocessable_entity
    assert_equal ["Name should not be blank"], json_body["errors"]
  end

  def test_new_success
    schedules = ::Desk::BusinessHours::Schedule::DAYS_NAMES.inject([]) do |schedules, day|
      schedules << {
        "id" => nil,
        "status" => "inactive",
        "day" => day,
        "from" => Desk::BusinessHours::CreationService::FROM_TIME,
        "to" => Desk::BusinessHours::CreationService::TO_TIME
      }
    end

    expected_response = {
      "business_hour" => {
        "id" => nil,
        "name" => nil,
        "description" => nil,
        "time_zone" => "Eastern Time (US & Canada)",
        "schedules" => schedules
      }
    }
    get new_api_v1_desk_business_hour_url, headers: headers(@user)
    assert_response :ok
    assert_equal expected_response["business_hour"]["time_zone"],
      json_body["business_hour"]["time_zone"]
    assert json_body["business_hour"]["schedules"]
    assert json_body["business_hour"]["time_zones"]
  end

  def test_destroy_success
    group = create(:group, business_hour: @business_hour)
    assert_difference "Desk::BusinessHour.count", -1 do
      delete api_v1_desk_business_hour_url(@business_hour.id), headers: headers(@user)
      assert_response :ok
      assert_equal "Business Hour has been successfully deleted", json_body["notice"]
    end
  end

  def test_destroy_failure
    delete api_v1_desk_business_hour_url(0),
      headers: headers(@user)
    assert_response :not_found
  end

  def test_index_success_with_search
    ["AceInvoice", "NeetoDesk", "Spinkart", "AceKart"].each do |name|
      create(:business_hour, name:, organization: @organization)
    end

    business_hour_params = {
      business_hour: {
        search_term: "aceinvoice"
      }
    }

    get api_v1_desk_business_hours_url, params: business_hour_params, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["business_hours"].count
    assert_equal "AceInvoice", json_body["business_hours"][0]["name"]
  end

  def test_index_with_sorted_names
    ["AceInvoice", "NeetoDesk"].each do |name|
      create(:business_hour, name:, organization: @organization)
    end

    business_hour_params = {
      business_hour: {
        name: "AceInvoice"
      }
    }

    get api_v1_desk_business_hours_url, params: business_hour_params, headers: headers(@user)
    business_hours = @organization.business_hours.order(:name)

    assert_response :ok
    assert_equal business_hours.count, json_body["business_hours"].count
    assert_equal business_hours[0].id, json_body["business_hours"][0]["id"]
  end

  def test_index_with_sort_by
    ["Eastern", "Western", "Northern"].each do |name|
      create(:business_hour, name:, organization: @organization)
    end
    get api_v1_desk_business_hours_url, params: { business_hour: { column: "name", direction: "desc" } },
      headers: headers(@user)

    assert_response :ok
    assert_equal "Western", json_body["business_hours"][0]["name"]
    assert_equal "Sales", json_body["business_hours"][1]["name"]
    assert_equal "Northern", json_body["business_hours"][2]["name"]
    assert_equal "Eastern", json_body["business_hours"][3]["name"]
  end

  def test_business_hours_list_is_paginated
    13.times { |i| create(:business_hour, name: i, organization: @organization) }

    get api_v1_desk_business_hours_url,
      headers: headers(@user),
      params: { business_hour: { page_index: 1, page_size: 5 } }

    assert_response :ok
    assert_equal 5, json_body["business_hours"].size
    assert_equal 15, json_body["total_count"]
  end
end
