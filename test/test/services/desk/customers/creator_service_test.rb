# frozen_string_literal: true

require "test_helper"

class Desk::Customers::CreatorServiceTest < ActiveSupport::TestCase
  def setup
    @user = create :user
    @organization = @user.organization

    @customer_params = {
      first_name: "Jon",
      customer_detail_attributes: {
        language: "High Valyrian",
        time_zone: "Eastern Time (US & Canada)",
        about: "About jon"
      },
      email_contact_details_attributes: [
        {
          value: "jon@example.com",
          primary: "true"
        },
        {
          value: "jon@gmail.com",
          primary: "false"
        }
      ],
      link_contact_details_attributes: [
        {
          value: "http://github.com/jon"
        }
      ],
      phone_contact_details_attributes: [
        {
          value: "978353499453"
        }
      ]
    }
  end

  def test_process_success
    assert_difference "User.where(role: nil).count", 1 do
      customer_service = Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params
      )
      customer_service.process

      customer = find_customer_by_primary_email

      assert_equal :ok, customer_service.status
      assert_equal "Successfully added 'Jon' as a new customer.", customer_service.response[:notice]
      assert_equal 2, customer.email_contact_details.count
      assert_nil customer.role
    end
  end

  def test_process_failure_without_primary_email
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon@example.com",
        primary: "false"
      },
      {
        value: "jon@gmail.com",
        primary: "false"
      }
    ]

    assert_no_difference "User.where(role: nil).count" do
      customer_service = Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params
      )
      customer_service.process

      assert_equal :unprocessable_entity, customer_service.status
      assert_includes customer_service.errors, "Primary email is required"
    end
  end

  def test_process_failure_with_invalid_primary_email
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon.com",
        primary: "true"
      },
      {
        value: "jon@gmail.com",
        primary: "false"
      }
    ]

    assert_no_difference "User.where(role: nil).count" do
      customer_service = Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params
      )
      customer_service.process

      assert_equal :unprocessable_entity, customer_service.status
      assert_includes customer_service.errors, "Email is invalid"
    end
  end

  def test_process_failure_if_customer_already_exists
    Desk::Customers::CreatorService.new(
      @organization,
      @user,
      @customer_params
    ).process
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon@example.com",
        primary: "true"
      }
    ]

    assert_no_difference "User.where(role: nil).count" do
      customer_service = Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params
      )
      customer_service.process

      assert_equal :unprocessable_entity, customer_service.status
      assert_includes customer_service.errors, "Email #{@customer_params[:email_contact_details_attributes].first[:value]} already exists."
    end
  end

  def test_process_create_success_but_update_failure_with_invalid_secondary_email
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon@example.com",
        primary: "true"
      },
      {
        value: "jon.com",
        primary: "false"
      }
    ]

    assert_difference "User.where(role: nil).count", 1 do
      customer_service = Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params
      )
      customer_service.process

      assert_equal :ok, customer_service.status
      assert_equal "Successfully added 'Jon' as a new customer.",
        customer_service.response[:notice]
      assert_equal 1, find_customer_by_primary_email.email_contact_details.count
      assert_equal "jon@example.com", find_customer_by_primary_email.email_contact_details.first.value
    end
  end

  def test_process_create_skips_invalid_secondary_email
    @customer_params[:email_contact_details_attributes] = [
      {
        value: "jon@example.com",
        primary: "true"
      },
      {
        value: "  ",
        primary: "false"
      },
      {
        value: "jon@abc.com",
        primary: "false"
      },
      {
        value: "jon@abc.com",
        primary: "false"
      }
    ]

    assert_difference "User.where(role: nil).count", 1 do
      customer_service = Desk::Customers::CreatorService.new(
        @organization,
        @user,
        @customer_params
      )
      customer_service.process

      customer = find_customer_by_primary_email
      primary_email = ::EmailContactDetail.where(primary: true, user_id: customer.id)
      secondary_email = ::EmailContactDetail.where(primary: false, user_id: customer.id)

      assert_equal :ok, customer_service.status
      assert_equal "Successfully added 'Jon' as a new customer.",
        customer_service.response[:notice]
      assert_equal 2, customer.email_contact_details.count
      assert_equal 1, primary_email.length
      assert_equal 1, secondary_email.length
      assert_equal "jon@example.com", primary_email.first[:value]
      assert_equal "jon@abc.com", secondary_email.first[:value]
    end
  end

  def test_user_name_is_self_extracted_from_email_if_not_provided
    customer_params = {
      customer_detail_attributes: {
        language: "High Valyrian",
        time_zone: "Eastern Time (US & Canada)",
        about: "About jon"
      },
      email_contact_details_attributes: [
        {
          value: "jonnyboy@example.com",
          primary: "true"
        }
      ]
    }

    customer_service = Desk::Customers::CreatorService.new(
      @organization,
      @user,
      customer_params
    )
    customer_service.process

    customer = User.find_by_email("jonnyboy@example.com")
    assert_equal customer.first_name, "jonnyboy"
  end

  private

    def find_customer_by_primary_email
      ::User.find_by_email("jon@example.com")
    end
end
