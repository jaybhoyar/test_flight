# frozen_string_literal: true

require "test_helper"

class Desk::Customers::FetchOrCreateServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @organization = @user.organization
  end

  def test_create_fails_with_invalid_email_address
    invalid_email = "12.com"

    assert_raises ActiveRecord::RecordInvalid do
      Desk::Customers::FetchOrCreateService.new(@organization, invalid_email).process
    end
  end

  def test_create_fails_for_user
    email = @user.email

    assert_difference "@organization.users.count", 0 do
      Desk::Customers::FetchOrCreateService.new(@organization, email).process
    end
  end

  def test_creates_customer_successfully_with_valid_email_address
    valid_email = "brucewayne@gotham.com"

    assert_difference "@organization.users.count", 1 do
      Desk::Customers::FetchOrCreateService.new(@organization, valid_email).process
    end
  end

  def test_creates_customer_with_name_as_first_part_of_email
    valid_email = "brucewayne@example.com"

    user = Desk::Customers::FetchOrCreateService.new(@organization, valid_email).process

    assert_equal "Brucewayne", user.name
  end

  def test_creates_customer_when_name_specified
    @user = Desk::Customers::FetchOrCreateService.new(@organization, "hugh@jack.com", "jack").process
    assert_equal "jack", @user.first_name
    assert_equal "hugh@jack.com", @user.email
  end

  def test_customer_is_found_using_secondary_email_from_email_contact_details
    user = create(:user, organization: @organization)

    user_email_contact_details = create(:email_contact_detail, user:)

    user = Desk::Customers::FetchOrCreateService
      .new(@organization, user_email_contact_details.value.downcase)
      .process

    assert_equal user.id, user.id
  end

  def test_customer_is_not_found_using_secondary_email_from_email_contact_details_if_organization_do_not_match
    organization = create(:organization)

    user_email_contact_details = create(:email_contact_detail, user: @user)

    assert_difference "User.count" do
      user = Desk::Customers::FetchOrCreateService
        .new(organization, user_email_contact_details.value.downcase)
        .process
    end
  end

  def test_that_company_is_assigned_properly
    other_organization = create :organization
    other_company = create :company, organization: other_organization, name: "ATOS"
    other_doamin = create :company_domain, company: other_company, name: "atos.com"

    user_1 = Desk::Customers::FetchOrCreateService.new(@organization, "hugh@atos.com", "jack").process
    assert_equal "jack", user_1.first_name
    assert_equal "hugh@atos.com", user_1.email
    assert_nil user_1.company

    company = create :company, organization: @organization, name: "Tata"
    doamin = create :company_domain, company: company, name: "tata.com"

    user_2 = Desk::Customers::FetchOrCreateService.new(@organization, "ratan@tata.com", "Ratan").process
    assert_equal "Ratan", user_2.first_name
    assert_equal "ratan@tata.com", user_2.email
    assert_equal company, user_2.company
  end
end
