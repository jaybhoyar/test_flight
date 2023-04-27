# frozen_string_literal: true

class Api::V1::Desk::Twitter::OauthController < Api::V1::BaseController
  def request_token
    response = ::Desk::Integrations::Twitter::OauthService.new({}, @organization).request_token
    render status: :ok, json: response
  end
end
