# frozen_string_literal: true

class Api::V1::Admin::PermissionsController < Api::V1::BaseController
  def index
    @permissions = Permission.all
  end
end
