# frozen_string_literal: true

module Desk::Integrations::Twitter
  class OauthService
    class TokenNotFoundError < StandardError
    end

    attr_accessor :details

    OAUTH_BASE_URL = "https://api.twitter.com/oauth"

    def initialize(details = {}, organization = nil, access_token = nil)
      @details = details
      @organization = organization
      @access_token = access_token
    end

    def request_token
      account = Desk::Twitter::Account.new(env_name: "dev")
      result = account.request_token
      if result[:oauth_callback_confirmed]
        account.update!(
          oauth_token: result[:oauth_token],
          oauth_token_secret: result[:oauth_token_secret],
          oauth_status: "open",
          env_name: Desk::Twitter::Account::ENV_NAME,
          organization_id: @organization.id
        )
        { success: true, redirect_url: url = "#{OAUTH_BASE_URL}/authenticate?oauth_token=#{result[:oauth_token]}" }
      else
        { success: false, error: "An error occured while processing the request" }
      end
    end

    def complete_oauth
      token_account = Desk::Twitter::Account.where(oauth_token: details[:oauth_token]).first
      raise TokenNotFoundError,
        "Invalid Token Request" unless token_account

      options = details.slice(:oauth_token, :oauth_verifier)
      result = @access_token || token_account.request_access_token(options)
      organization = Organization.find(token_account.organization_id)

      account = Desk::Twitter::Account.where(
        oauth_user_id: result[:user_id], env_name: Desk::Twitter::Account::ENV_NAME, organization_id: organization.id
      ).first_or_create
      account.update!(
        oauth_token: result[:oauth_token],
        oauth_token_secret: result[:oauth_token_secret],
        oauth_user_id: result[:user_id],
        screen_name: result[:screen_name]
      )
      account.reload
      account.subscribe
      token_account.delete

      organization
    end
  end
end
