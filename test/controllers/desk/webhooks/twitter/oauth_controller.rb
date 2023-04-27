# frozen_string_literal: true

module Desk
  module Webhooks::Twitter
    class OauthController < ApplicationController
      respond_to :json
      skip_before_action :verify_authenticity_token, :load_organization

      def callback
        details = process_params.to_h
        redirect_on_denied(details)

        result = process_account_params(details)
        if result[:screen_name] != nil && Desk::Twitter::Account.find_by_screen_name(result[:screen_name])
          @token_account.destroy!

          redirect_to @organization.root_url + "desk/settings/twitter_accounts?error=screen_name"
        else
          organization = ::Desk::Integrations::Twitter::OauthService.new(details, nil, result).complete_oauth

          redirect_to organization.root_url + "desk/settings/twitter_accounts"
        end
      rescue ::Desk::Integrations::Twitter::OauthService::TokenNotFoundError => exception
        log_exception(exception)
        redirect_to Rails.application.secrets[:auth_app][:url]
      end

      private

        def process_params
          params.permit(:oauth_token, :oauth_verifier, :denied)
        end

        def process_account_params(details)
          @token_account = Desk::Twitter::Account.where(oauth_token: details[:oauth_token]).first
          raise ::Desk::Integrations::Twitter::OauthService::TokenNotFoundError,
            "Invalid Token Request" unless @token_account

          options = details.slice(:oauth_token, :oauth_verifier)
          @organization = Organization.find(@token_account.organization_id)
          @token_account.request_access_token(options)
        end

        def redirect_on_denied(details)
          return if details[:oauth_token]

          if details[:denied] && (token_account = Desk::Twitter::Account.where(oauth_token: details[:denied]).first)
            organization = Organization.find(token_account.organization_id)
            redirect_to "#{organization.root_url}desk/settings/twitter_accounts" && return
          else
            raise ::Desk::Integrations::Twitter::OauthService::TokenNotFoundError, "Invalid Token Request"
          end
        end
    end
  end
end
