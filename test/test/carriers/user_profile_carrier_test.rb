# frozen_string_literal: true

require "test_helper"

class UserProfileCarrierTest < ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers

  def test_attributes
    user = create :user

    carrier = UserProfileCarrier.new(user, user.organization)

    attributes = {
      profile_image_path: carrier.profile_image_path,
      profile_name: user.name,
      is_admin: false,
      email: user.email
    }
    assert_equal attributes, carrier.profile_attributes
  end
end
