# frozen_string_literal: true

def json_body
  JSON.parse(response.body)
end

def headers(user)
  {
    "X-Auth-Token" => user.authentication_token,
    "X-Auth-Email" => user.email
  }
end

def app_secrets
  @_app_secrets ||= Rails.application.secrets
end

def with_caching
  Rails.cache.clear
  yield

ensure
  Rails.cache.clear
end

def token_headers
  headers = {
    "Content-Type" => "application/json",
    "Authorization" => encoded_client_authorization_token
  }
end

def encoded_client_authorization_token
  ActionController::HttpAuthentication::Token
    .encode_credentials(Rails.application.secrets.server_authorization_token)
end
