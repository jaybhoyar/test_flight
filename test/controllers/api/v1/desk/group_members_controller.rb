# frozen_string_literal: true

class Api::V1::Desk::GroupMembersController < Api::V1::BaseController
  def index
    @users = @organization.users
  end
end
