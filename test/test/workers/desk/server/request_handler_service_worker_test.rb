# frozen_string_literal: true

require "test_helper"

class Desk::Server::RequestHandlerServiceWorkerTest < ActiveSupport::TestCase
  def setup
    Sidekiq::Testing.inline!
  end

  def test_that_api_request_is_processed
    stub_request(:post, "http://#{test_domain}/api/v1/server/organizations")
      .with(
        body: organization_params.to_json,
        headers: request_hash["headers"]
      )
      .to_return(status: 200, body: "", headers: {})

    Desk::Server::RequestHandlerServiceWorker.perform_async(request_hash, request_options, service_options)
  end

  private

    def request_hash
      {
        url: "http://#{test_domain}/api/v1/server/organizations",
        headers: { "Authorization" => "Token token=\"tokendldfjdf\"" },
        body: organization_params
      }.deep_stringify_keys
    end

    def service_options
      {
        run: true,
        worker: "Desk::Server::RequestHandlerServiceWorker"
      }.deep_stringify_keys
    end

    def request_options
      {
        method: "post"
      }.deep_stringify_keys
    end

    def organization_params
      {
        name: "organame"
      }
    end
end
