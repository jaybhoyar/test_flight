# frozen_string_literal: true

require "test_helper"
class Desk::Organizations::Users::CreatorServiceTest < ActiveSupport::TestCase
  def setup
    subdomain = "flipmart"
    @organization = create(:organization, subdomain:, auth_app_url: "http://#{test_domain(subdomain)}")
    @user = create(:user_with_admin_role, organization: @organization)
    ActionMailer::Base.deliveries = []
  end

  def test_add_new_user_to_organization
    options = {
      first_name: "Oliver",
      last_name: "Smith",
      role: nil,
      email: "oliver@example.com",
      time_zone_offset: -330
    }

    user_service = Desk::Organizations::Users::CreatorService.new(@organization, @user, options)
    assert_emails 0 do
      user_service.process
    end

    oliver = @organization.users.find_by(email: "oliver@example.com")
    assert oliver.confirmed?
    assert_equal "Chennai", oliver.time_zone
    assert_equal "Successfully added 'Oliver Smith' as a new customer.", user_service.response[:notice]
  end

  def test_that_invitation_request_sent_to_neeto_auth_if_role_not_customer_and_sso_enabled
    role = create :organization_role_agent
    options = {
      first_name: "Oliver",
      last_name: "Oyl",
      organization_role_id: role.id,
      email: "oliveoyl@example.com",
      time_zone_offset: -330
    }

    stub_invitation_request(options, 200)

    Desk::Organizations::Users::CreatorService.any_instance.stubs(:sso_enabled?).returns(true)
    creator_service = Desk::Organizations::Users::CreatorService.new(@organization, @user, options)

    assert_difference "User.count", 1 do
      creator_service.process
    end
  end

  def test_that_user_is_rollbacked_if_sso_enabled_and_request_fails
    role = create :organization_role_agent
    options = {
      first_name: "Oliver",
      last_name: "Oyl",
      organization_role_id: role.id,
      email: "oliveoyl@example.com",
      time_zone_offset: -330
    }

    stub_invitation_request(options, 422)

    Desk::Organizations::Users::CreatorService.any_instance.stubs(:sso_enabled?).returns(true)
    creator_service = Desk::Organizations::Users::CreatorService.new(@organization, @user, options)

    assert_no_difference "User.count" do
      creator_service.process
    end
  end

  def test_add_new_user_without_role
    options = { first_name: "Oliver", last_name: "Smith", email: "oliver@example.com" }

    user_service = Desk::Organizations::Users::CreatorService.new(@organization, @current_user, options)
    user_service.process
    assert_equal :ok, user_service.status
  end

  def test_add_existing_user_to_organization
    options = {
      email: @user.email,
      first_name: @user.first_name,
      last_name: @user.last_name
    }

    user_service = Desk::Organizations::Users::CreatorService.new(@organization, @user, options)
    user_service.process
    assert_equal "Email #{@user.email} already exists.", user_service.errors
  end

  def test_add_existing_customer_to_organization
    @user.update!(role: nil)

    options = {
      email: @user.email,
      first_name: @user.first_name,
      last_name: @user.last_name
    }

    user_service = Desk::Organizations::Users::CreatorService.new(@organization, @user, options)
    user_service.process
    assert_equal "Email #{@user.email} already exists.",
      user_service.errors
  end

  private

    def stub_invitation_request(user_attributes, response_code)
      stub_request(:post, ->(uri) { uri.to_s.include?("/api/v1/clients/invitations") }).with(
        body: hash_including(
          {
            "user" => {
              "email" => user_attributes[:email],
              "first_name" => user_attributes[:first_name],
              "last_name" => user_attributes[:last_name],
              "role" => "non_owner"
            }
          }),
        headers: {
          "Authorization" => "Bearer",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      ).to_return(status: response_code, body: "", headers: {})
    end
end
