# frozen_string_literal: true

require "minitest/assertions"

module Minitest::Assertions
  def assert_policy(current_user, record, action)
    assert permit(current_user, record, action)
  end

  def refute_policy(current_user, record, action)
    refute permit(current_user, record, action)
  end

  private

    def permit(current_user, record, action)
      Pundit.authorize(current_user, record, action)
    rescue Pundit::NotAuthorizedError
      false
    end
end
