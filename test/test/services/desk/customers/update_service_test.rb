# frozen_string_literal: true

require "test_helper"

class Desk::Customers::UpdateServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create :organization
    @customer = create(:user, organization: @organization, role: nil)
    @primary_email = @customer.email_contact_details.first
    @secondary_email = create(:email_contact_detail, user: @customer)
    @customer_tag1 = create(:customer_tag, name: "VIP", organization: @organization)
    @customer_tag2 = create(:customer_tag, name: "Member", organization: @organization)
    @customer_detail = create :customer_detail, user: @customer

    @customer.customer_detail.update!(tags: [@customer_tag1])

    @customer_params = {
      first_name: "Jon",
      last_name: "Snow",
      organization_id: @organization.id,
      phone_contact_details_attributes: [{
        label: "Mobile number",
        value: "9090909090",
        _destroy: "false"
      }],
      link_contact_details_attributes: [{
        label: "Google",
        value: "https://www.google.com",
        _destroy: "false"
      }],
      customer_detail_attributes: {
        language: "High Valyrian",
        time_zone: "Eastern Time (US & Canada)",
        about: "About jon",
        tags: [@customer_tag1]
      },
      email_contact_details_attributes: [
        {
          value: "jon@example.com",
          primary: "false",
          id: @primary_email.id,
          _destroy: "true"
        },
        {
          value: "jon@gmail.com",
          primary: "false",
          id: @secondary_email.id
        },
        {
          value: "jon@example.us",
          primary: "true"
        }
      ]
    }
  end

  def test_process_success
    service = customer_update_service

    assert_no_difference "EmailContactDetail.count" do
      service.process
    end

    assert_equal :ok, service.status
    assert_equal "Jon Snow's details have been updated successfully.", service.response[:notice]
    assert_equal "Jon Snow", @customer.reload.name
    assert_equal "jon@gmail.com", @secondary_email.reload.value
    assert_equal 2, @customer.email_contact_details.count
    assert_equal 1, @customer.customer_detail.tags.count
    assert @customer.active?

    assert_raises ActiveRecord::RecordNotFound do
      @primary_email.reload
    end
  end

  def test_process_does_not_destroy_primary_email
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "new@example.com",
        primary: "true",
        id: @primary_email.id,
        _destroy: "true"
      }
    ]

    customer_service = customer_update_service
    customer_service.process

    assert_equal :ok, customer_service.status
    assert_equal "Jon Snow's details have been updated successfully.", customer_service.response[:notice]
    assert @primary_email.reload.primary?
    assert_equal "new@example.com", @customer.email
    assert_equal @customer.email, @primary_email.value
    assert_equal 2, @customer.email_contact_details.count
  end

  def test_process_fails_for_invalid_primary_emails
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon",
        primary: "true",
        id: @primary_email.id
      }
    ]

    customer_service = customer_update_service
    customer_service.process

    assert_equal :unprocessable_entity, customer_service.status
    assert_includes customer_service.errors, "Email contact details value is invalid"
    assert_equal @customer.email, @primary_email.reload.value
  end

  def test_process_fails_for_invalid_secondary_emails
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon",
        primary: "false",
        id: @secondary_email.id
      }
    ]

    customer_service = customer_update_service
    customer_service.process

    assert_equal :unprocessable_entity, customer_service.status
    assert_includes customer_service.errors, "Email contact details value is invalid"
    assert_equal @secondary_email.value, @secondary_email.reload.value
  end

  def test_process_takes_one_from_multiple_primary_emails
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon@example.nz",
        primary: "true"
      },
      {
        value: "jon@example.ca",
        primary: "true"
      }
    ]

    customer_service = customer_update_service

    assert_difference "EmailContactDetail.count", 1 do
      customer_service.process
    end

    assert_equal :ok, customer_service.status
    assert_equal "Jon Snow's details have been updated successfully.", customer_service.response[:notice]
    assert_not @primary_email.reload.primary?
    assert_equal 3, @customer.email_contact_details.count
  end

  def test_fails_update_to_zero_primary_emails
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon@example.com",
        primary: "false",
        id: @primary_email.id
      }
    ]

    customer_service = customer_update_service
    customer_service.process

    assert_equal @primary_email.value, @primary_email.reload.value
    assert_equal @customer.email, @primary_email.value
    assert @primary_email.primary?
    assert_equal 2, @customer.email_contact_details.count
  end

  def test_removes_all_tags_from_customer
    @customer_params[:customer_detail_attributes][:tags] = []

    customer_service = customer_update_service
    customer_service.process

    assert_equal 0, @customer.reload.customer_detail.tags.count
    assert_equal 0, @customer_tag1.reload.customer_details.count
    assert_equal 0, @customer_tag2.reload.customer_details.count
  end

  def test_adds_tags_to_customer
    @customer_params[:customer_detail_attributes][:tags] = [
      @customer_tag1,
      @customer_tag2
    ]

    customer_service = customer_update_service
    customer_service.process

    assert_equal 2, @customer.reload.customer_detail.tags.count
    assert_equal 1, @customer_tag1.reload.customer_details.count
    assert_equal 1, @customer_tag2.reload.customer_details.count
  end

  def test_outbound_message_event_is_destroyed_before_update_service_is_run
    outbound_message_event = create(
      :message_event, user: @customer,
      email_contact_detail: @customer.email_contact_details.first)

    customer_service = customer_update_service
    customer_service.process

    assert_equal :ok, customer_service.status
  end

  private

    def customer_update_service
      Desk::Customers::UpdateService.new(
        @organization,
        @customer,
        @customer_params
      )
    end
end
