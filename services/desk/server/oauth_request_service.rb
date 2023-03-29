
# frozen_string_literal: true

# The requests which are handled from the application's admin section.
# The requests are made to the neetoAuth server using oauth token of resource owner.
# The resource owner is admin of the organization.

class Desk::Server::OauthRequestService
  attr_reader :resource_owner, :status, :response

  def initialize(resource_owner)
    @resource_owner = resource_owner
    @status = 202
    @response = {}
  end

  def process(request_verb, request_path, request_params)
    refresh_doorkeeper_token if doorkeeper_access_token.expired?

    oauth2_response = if request_verb == :post
      doorkeeper_access_token.post(request_path, request_params)
    elsif request_verb == :put
      doorkeeper_access_token.put(request_path, request_params)
    end

    set_response(oauth2_response)
    response
  end

  def success?
    status == 200
  end

  private

    def set_response(oauth2_response)
      @status = oauth2_response.status

      if success?
        @response = oauth2_response.parsed
      else
        if oauth2_response.parsed.present?
          @response = oauth2_response.parsed
        else
          @response = { error: oauth2_response.response.reason_phrase }
        end

        Rails.logger.error "[Error] oauth response => #{response.inspect}"
      end
    end

    def doorkeeper_access_token
      OAuth2::AccessToken.new(
        doorkeeper_oauth_client,
        resource_owner.doorkeeper_access_token,
        {
          refresh_token: resource_owner.doorkeeper_refresh_token,
          expires_at: resource_owner.doorkeeper_token_expires_at
        }
      )
    end

    def doorkeeper_oauth_client
      OAuth2::Client.new(
        organization.auth_app_id,
        organization.auth_app_secret,
        site: organization.auth_app_url
      )
    end

    def refresh_doorkeeper_token
      new_oauth_access_token = doorkeeper_access_token.refresh!

      resource_owner.update(
        doorkeeper_access_token: new_oauth_access_token.token,
        doorkeeper_refresh_token: new_oauth_access_token.refresh_token,
        doorkeeper_token_expires_at: new_oauth_access_token.expires_at
      )
    end

    def organization
      @_organization ||= Organization.current || resource_owner.organization
    end

    def app_secrets
      @_app_secrets = Rails.application.secrets
    end
end
