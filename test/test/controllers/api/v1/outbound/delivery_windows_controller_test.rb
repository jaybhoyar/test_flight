# frozen_string_literal: true

require "test_helper"

class Api::V1::Outbound::DeliveryWindowsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user)
    @organization = @user.organization
    @outbound_message = create(:outbound_message)
    sign_in(@user)
    host! test_domain(@organization.subdomain)
  end

  def test_create_success
    assign_name = Faker::Team.name
    outbound_delivery_window_params = {
      delivery_window:
      attributes_for(
        :outbound_delivery_window,
        name: assign_name).merge(schedules_attributes: { "0": attributes_for(:schedule, status: "active") })
    }

    assert_difference "Outbound::DeliveryWindow.count", 1 do
      post api_v1_outbound_message_delivery_windows_url(@outbound_message.id, outbound_delivery_window_params),
        headers: headers(@user)
      assert_response :ok
      assert_equal "Delivery window has been successfully added.", json_body["notice"]
      assert_equal assign_name, Outbound::DeliveryWindow.last.name
    end
  end

  def test_create_failure
    outbound_delivery_window_params = {
      delivery_window:
      attributes_for(
        :outbound_delivery_window,
        name: "").merge(schedules_attributes: { "0": attributes_for(:schedule, status: "active") })
    }

    post api_v1_outbound_message_delivery_windows_url(@outbound_message.id, outbound_delivery_window_params),
      headers: headers(@user)
    assert_response :unprocessable_entity
    assert_equal ["Name can't be blank"], json_body["errors"]
  end

  def test_new_success
    schedules = Outbound::DeliveryWindow::Schedule::DAYS_NAMES.inject([]) do |schedules, day|
      schedules << {
        "id" => nil,
        "status" => "inactive",
        "day" => day,
        "from" => Desk::Outbound::DeliveryWindowService::FROM_TIME,
        "to" => Desk::Outbound::DeliveryWindowService::TO_TIME
      }
    end

    expected_response = {
      "outbound_delivery_window" => {
        "id" => nil,
        "name" => Desk::Outbound::DeliveryWindowService::DEFAULT_NAME,
        "description" => nil,
        "time_zone" => "Eastern Time (US & Canada)",
        "schedules" => schedules
      }
    }

    get new_api_v1_outbound_message_delivery_window_url(@outbound_message.id), headers: headers(@user)

    assert_response :ok
    assert_equal expected_response["outbound_delivery_window"]["time_zone"],
      json_body["outbound_delivery_window"]["time_zone"]
    assert json_body["outbound_delivery_window"]["time_zones"]
  end

  def test_index_success
    outbound_delivery_window = create(:outbound_delivery_window, message_id: @outbound_message.id)

    get api_v1_outbound_message_delivery_windows_url(@outbound_message.id), headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["outbound_delivery_windows"].size
    assert_equal outbound_delivery_window.name, json_body["outbound_delivery_windows"][0]["name"]
    assert_equal outbound_delivery_window.time_zone, json_body["outbound_delivery_windows"][0]["time_zone"]
    assert outbound_delivery_window.schedules.all? { |schedule| schedule.active? }
  end

  def test_edit_success
    outbound_delivery_window = create(:outbound_delivery_window, message: @outbound_message)
    create(:delivery_schedule, delivery_window: outbound_delivery_window)

    get edit_api_v1_outbound_message_delivery_window_url(@outbound_message.id, outbound_delivery_window.id),
      headers: headers(@user)

    assert_response :ok
    assert_equal outbound_delivery_window.id, json_body["outbound_delivery_window"]["id"]
    assert_equal outbound_delivery_window.name, json_body["outbound_delivery_window"]["name"]

    schedule_data = outbound_delivery_window.schedules
    schedule_data = schedule_data.map do |schedule|
      {
        id: schedule.id,
        day: schedule.day,
        status: schedule.status,
        to: schedule.to,
        from: schedule.from
      }

    end
    assert_equal JSON.parse(schedule_data.to_json),
      json_body["outbound_delivery_window"]["schedules"]
  end

  def test_update_success
    outbound_delivery_window = create(:outbound_delivery_window, message: @outbound_message)
    schedule_id = create(:delivery_schedule, delivery_window: outbound_delivery_window).id
    payload = {
      delivery_window: {
        time_zone: "Kolkata",
        schedules_attributes: {
          schedule_id => {
            from: "2/2/2020 06:00",
            to: "2/2/2020 15:00",
            status: "active"
          }
        }
      }
    }

    patch api_v1_outbound_message_delivery_window_url(@outbound_message.id, outbound_delivery_window.id),
      headers: headers(@user), params: payload

    assert_response :ok
    assert_equal "Delivery window has been successfully updated.", json_body["notice"]
  end

  def test_update_failure
    outbound_delivery_window = create(:outbound_delivery_window, message: @outbound_message)

    payload = { delivery_window: { name: "" } }
    patch api_v1_outbound_message_delivery_window_url(@outbound_message.id, outbound_delivery_window.id),
      headers: headers(@user), params: payload

    assert_response :unprocessable_entity
    assert_equal ["Name can't be blank"], json_body["errors"]
  end

  def test_destroy_success
    outbound_delivery_window = create(:outbound_delivery_window, message: @outbound_message)

    assert_difference "Outbound::DeliveryWindow.count", -1 do
      delete api_v1_outbound_message_delivery_window_url(@outbound_message.id, outbound_delivery_window.id),
        headers: headers(@user)
      assert_response :ok
      assert_equal "Delivery window has been successfully deleted.", json_body["notice"]
    end
  end
end
