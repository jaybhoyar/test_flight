# frozen_string_literal: true

class Desk::Server::RequestHandlerService
  REQUEST_OPTIONS = {
    timeout: 3,
    connecttimeout: 2,
    ssl_verifypeer: false,
    method: :post
  }

  class RequestFailedError < StandardError; end

  attr_reader :request_hash, :request_options, :service_options, :request

  # service_options :run
  # run is set to true when making api request individually from a worker.
  # run is set to false when hydra makes requests in parallel.

  # service_options :worker
  # Worker class name which will be run in background when any request fails

  def initialize(request_hash, typhoeus_options = {}, service_options = {})
    @request_hash = request_hash
    @request_options = {
      body: request_hash[:body],
      headers: request_hash[:headers]
    }.merge(REQUEST_OPTIONS)
      .merge(typhoeus_options)

    @service_options = service_options
    typhoeus_request_options = request_options.merge(body: request_hash[:body].to_json)

    @request = Typhoeus::Request.new(request_hash[:url], typhoeus_request_options)
  end

  def process
    if service_options[:run]
      handle_response
      request.run
    end

    request
  end

  def handle_response
    request.on_complete do |response|
      if response.success?
        Sidekiq.logger.info "Server API request [SUCCESS] #{request_hash[:url]}"
      elsif response.timed_out?
        Sidekiq.logger.error "Server API request [TIMED OUT] at #{request_hash[:url]}"
        handle_request_failure
      elsif response.code.zero?
        Sidekiq.logger.error "Server API request [COULDN'T REACH] at #{request_hash[:url]}"
        handle_request_failure
      else
        Sidekiq.logger.error "Server API request [FAILED] with response code #{response.code} Response #{response.body}"
        handle_request_failure
      end
    end
  end

  private

    def handle_request_failure
      if service_options[:run]
        # Simply raise an error so Sidekiq will take care of the retrying
        raise RequestFailedError
      else
        return unless service_options[:worker]

        # Run a worker as it failed for the first time, stringify keys for sidekiq
        worker_klass.perform_async(
          request_hash.deep_stringify_keys,
          request_options.deep_stringify_keys,
          service_options.merge(run: true).deep_stringify_keys
        )
      end
    end

    def worker_klass
      Object.const_get(service_options[:worker])
    end
end
