# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::HolidaysControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @organization = @user.organization
    @business_hour = create :business_hour, organization: @organization
    sign_in @user
    host! test_domain(@organization.subdomain)
  end

  def test_index
    get api_v1_desk_business_hour_holidays_url(@business_hour.id), headers: headers(@user)
    assert_response :success
    assert json_body["holidays"]
  end

  def test_create_success
    payload = { holiday: { name: Faker::Name.name, date: Date.current } }
    assert_difference "Desk::BusinessHours::Holiday.count", 1 do
      post api_v1_desk_business_hour_holidays_url(@business_hour.id, payload), headers: headers(@user)
    end
    assert_response :success
    assert_equal "Holiday has been successfully created.", json_body["notice"]
  end

  def test_create_failure
    payload = { holiday: { name: nil, date: Date.current } }
    post api_v1_desk_business_hour_holidays_url(@business_hour.id, payload), headers: headers(@user)
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name can't be blank"
  end

  def test_update_success
    holiday = create(:holiday, business_hour: @business_hour)
    payload = { holiday: attributes_for(:holiday) }
    patch api_v1_desk_business_hour_holiday_url(
      @business_hour.id,
      holiday.id
                                          ), headers: headers(@user), params: payload
    assert_response :ok
    assert_equal "Holiday has been successfully updated.", json_body["notice"]
  end

  def test_update_failure
    holiday = create(:holiday, business_hour: @business_hour)
    payload = { holiday: attributes_for(:holiday, name: nil) }
    patch api_v1_desk_business_hour_holiday_url(
      @business_hour.id,
      holiday.id
                                          ), headers: headers(@user), params: payload
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name can't be blank"
  end

  def test_destroy_sucess
    holiday = create(:holiday, business_hour: @business_hour)

    assert_difference "Desk::BusinessHours::Holiday.count", -1 do
      delete api_v1_desk_business_hour_holiday_url(
        @business_hour.id,
        holiday.id
                                             ), headers: headers(@user)
      assert_response :ok
      assert_equal "Holiday has been successfully removed.", json_body["notice"]
    end
  end

  def test_destroy_failure
    delete api_v1_desk_business_hour_holiday_url(@business_hour.id, 0), headers: headers(@user)
    assert_response :not_found
  end
end
