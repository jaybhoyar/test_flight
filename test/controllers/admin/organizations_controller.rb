# frozen_string_literal: true

class Admin::OrganizationsController < Admin::BaseController
  def index
    @organizations = current_user.belonging_organizations
  end
end
