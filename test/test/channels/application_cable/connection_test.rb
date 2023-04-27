# frozen_string_literal: true

require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  include ActionCable::TestHelper
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create :user
    @organization = @user.organization
  end

  test "connects with valid params" do
    # Simulate a connection opening by calling the `connect` method
    connect params: { subdomain: @organization.subdomain, email: @user.email, auth_token: @user.authentication_token }
    # You can access the Connection object via `connection` in tests
    assert_equal connection.current_organization.id, @organization.id
  end

  test "rejects connection without valid params" do
    # Use `assert_reject_connection` matcher to verify that
    # connection is rejected
    assert_reject_connection { connect }
  end

  test "rejects connection with incorrect subdomain" do
    # Use `assert_reject_connection` matcher to verify that
    # connection is rejected
    assert_reject_connection {
      connect params: {
        subdomain: Faker::Internet.domain_word
      }
    }
  end

  test "rejects connection with incorrect user params" do
    # Use `assert_reject_connection` matcher to verify that
    # connection is rejected
    assert_reject_connection {
      connect params: {
        subdomain: @organization.subdomain,
        email: Faker::Internet.email,
        auth_token: SecureRandom.hex
      }
    }
  end
end
