# frozen_string_literal: true

# The requests which are meant to communicate from server to server.
# The requests are done using basic authentication.

class Desk::Server::BasicAuthRequestService
  def initialize(request_path, request_params, request_options = { method: "post" })
    @request_path = request_path
    @request_params = request_params
    @request_options = request_options
  end

  def process
    hydra = Typhoeus::Hydra.new(max_concurrency: 1)

    begin
      request_handler = Desk::Server::RequestHandlerService.new(request_hash, request_options, service_options)
      request_handler.process
      request_handler.handle_response

      hydra.queue(request_handler.request)

      hydra.run
    rescue StandardError => exception
      Rails.logger.error exception.class.to_s
      Rails.logger.error exception.to_s
      Rails.logger.error exception.backtrace.join("\n")
    end
  end

  private

    attr_reader :request_params, :request_path, :request_options

    def request_hash
      {
        url: api_url,
        body: request_params,
        headers:
      }
    end

    def api_url
      "#{server_application}#{request_path}"
    end

    def service_options
      {
        worker: "Desk::Server::RequestHandlerServiceWorker",
        run: false
      }
    end

    def server_application
      @_server_application ||= app_secrets.auth_app[:url].gsub(/app/, "www")
    end

    def headers
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => encoded_server_authorization_token
      }
    end

    def encoded_server_authorization_token
      ActionController::HttpAuthentication::Token
        .encode_credentials(app_secrets.server_authorization_token)
    end

    def app_secrets
      @_app_secrets ||= Rails.application.secrets
    end
end
