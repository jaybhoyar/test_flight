# frozen_string_literal: true

require "test_helper"

class Admin::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  def test_organization_index
    @user = create :user

    sign_in(@user)

    get organizations_path

    assert :success
  end
end
