# frozen_string_literal: true

require "test_helper"

class OnboardingStatesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create(:organization)
    host! test_domain(@organization.subdomain)
  end

  def test_update_success
    organization_params = { organization: { is_onboard: true } }

    patch onboarding_state_path, params: organization_params

    assert_response :success
    response_json = response.parsed_body
    assert_equal "Onboarding state has been successfully updated.", response_json["notice"]
  end
end
