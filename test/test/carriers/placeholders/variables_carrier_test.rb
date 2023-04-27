# frozen_string_literal: true

require "test_helper"

class Placeholders::VariablesCarrierTest < ActiveSupport::TestCase
  def test_that_all_keys_are_present_for_ticket
    placeholder_variables = ["ticket", "organization"]

    ticket = create :ticket
    placeholder = Placeholders::VariablesCarrier.new(ticket)

    assert_equal placeholder_variables, placeholder.build.keys
  end
end
