# frozen_string_literal: true

require "test_helper"

class Desk::Server::RequestHandlerServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
    @token = app_secrets.server_authorization_token
  end

  def test_that_should_call_organization_create_with_params
    stub_request(:post, "http://www.lvh.me:9000/api/v1/server/organizations").with(
      body: organization_params.to_json,
      headers: request_hash[:headers]
    ).to_return(status: 200, body: "", headers: {})

    request_handler = Desk::Server::RequestHandlerService.new(
      request_hash, { method: "post" },
      { run: false, worker: "Desk::Server::RequestHandlerServiceWorker" })
    result = request_handler.process

    assert_equal "Typhoeus::Request", result.class.name
  end

  private

    def request_hash
      {
        url: "http://www.lvh.me:9000/api/v1/server/organizations",
        headers: { "Authorization" => "Token token=\"#{@token}\"" },
        body: organization_params
      }
    end

    def organization_params
      {
        name: @organization.name
      }
    end
end
