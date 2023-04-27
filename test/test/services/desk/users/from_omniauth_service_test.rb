# frozen_string_literal: true

require "test_helper"

class Desk::Users::FromOmniauthServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    create(:organization_role_admin, organization: @organization)
    create(:organization_role_agent, organization: @organization)
    Organization.current = @organization
  end

  def teardown
    Organization.current = nil
  end

  def test_that_user_is_initialized_from_omniauth_hash
    auth_hash = omniauth_hash
    from_omniauth_service = Desk::Users::FromOmniauthService.new(auth_hash)

    assert_difference "User.count", 1 do
      from_omniauth_service.process
    end

    user = from_omniauth_service.user
    assert user.admin?
    assert_equal auth_hash.info.email, user.email
    assert from_omniauth_service.success?
  end

  def test_that_user_is_not_created_if_already_present_with_email_and_organization
    auth_hash = omniauth_hash
    from_omniauth_service = Desk::Users::FromOmniauthService.new(auth_hash)

    from_omniauth_service.process

    assert_difference "User.count", 0 do
      Desk::Users::FromOmniauthService.new(auth_hash).process
    end
  end

  def test_that_user_is_user_is_admin_when_no_admin_present
    auth_hash = omniauth_hash
    from_omniauth_service = Desk::Users::FromOmniauthService.new(auth_hash)
    from_omniauth_service.process

    assert from_omniauth_service.user.admin?

    auth_hash = omniauth_hash
    from_omniauth_service = Desk::Users::FromOmniauthService.new(auth_hash)
    from_omniauth_service.process

    assert from_omniauth_service.user.agent?
  end

  private

    def omniauth_hash(provider = "doorkeeper")
      first_name, last_name = Faker::Name.name.split(" ", 2)
      OmniAuth::AuthHash.new(
        {
          provider:,
          uid: Faker::Number.number(digits: 10),
          info: {
            email: Faker::Internet.email,
            first_name:,
            last_name:,
            date_format: "%m/%d/%Y"
          },
          credentials: {
            token: SecureRandom.hex(8),
            refresh_token: SecureRandom.hex(8),
            expires_at: DateTime.now
          }
        })
    end
end
