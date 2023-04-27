# frozen_string_literal: true

require "test_helper"

class Placeholders::UserCarrierTest < ActiveSupport::TestCase
  def test_that_all_keys_are_present
    supported_variables = [
      "id", "name", "email", "first_name", "last_name"
    ]

    user = create :user
    placeholder = Placeholders::UserCarrier.new(user)
    assert_equal supported_variables, placeholder.build.keys
  end
end
