# frozen_string_literal: true

require "test_helper"

class Desk::Server::OrganizationCreatorServiceTest < ActiveSupport::TestCase
  def setup
    @server_authorization_token = app_secrets.server_authorization_token
    @organization = create(:organization)
  end

  def test_organization_is_created_with_valid_subdomain
    stub_request(:post, "http://www.neetoauth.test#{app_secrets.routes[:auth_app][:basic][:organizations_api_path]}").with(
      body: {},
      headers: {
        "Authorization" => "Token token=\"#{@server_authorization_token}\""
      }
    ).to_return(status: 200, body: "", headers: {})

    organization_creator_service = Desk::Server::OrganizationCreatorService.new(@organization)
    result = organization_creator_service.process

    assert result
  end
end
