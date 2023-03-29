# frozen_string_literal: true

module Desk::Integrations::Twitter
  class WebhookService
    attr_accessor :details, :client

    def initialize(details = {}, client = nil)
      @details = details
      @client = client || fetch_client
    end

    # List all registered webhooks based on environments
    def fetch_all_webhooks
      client.list_webhooks(details[:env_name])
    end

    # Create/Register new webhook
    def create_webhook
      client.create_webhook(details[:env_name], details[:url])
    end

    # Delete already registered webhook
    def delete_webhook
      client.delete_webhook(details[:env_name], details[:webhook_id])
    end

    # Trigger twitter crc check manually
    def trigger_crc
      client.trigger_crc_check(details[:env_name], details[:webhook_id])
    end

    private

      def fetch_client
        @account = Desk::Twitter::Account.new
        @account.client
      end
  end
end
