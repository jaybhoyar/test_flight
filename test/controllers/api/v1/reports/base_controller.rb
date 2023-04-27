# frozen_string_literal: true

class Api::V1::Reports::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  include TokenAuthenticatable
  include ApiException
  include DateRangeSelectable
  include AssigneeFilterable
  include Authorizable

  before_action :authenticate_user_using_x_auth_token
  before_action :setup_date_range
end
