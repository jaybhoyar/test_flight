# frozen_string_literal: true

class Api::V1::BaseController < ApplicationController
  include ApiException
  include TokenAuthenticatable
  include Authorizable
  include Api::Authenticate
  DEFAULT_PER_PAGE = 15

  skip_before_action :verify_authenticity_token
end
