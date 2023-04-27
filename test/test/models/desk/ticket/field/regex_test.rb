# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class Field::RegexTest < ActiveSupport::TestCase
      def setup
        @field = create :ticket_field
      end

      test "regex custom field is not valid without condition" do
        regex_exp = Desk::Ticket::Field::Regex.new(
          condition: nil, help_message: "For number 0 to 9",
          ticket_field: @field)

        assert_not regex_exp.valid?

        assert_equal ["can't be blank"], regex_exp.errors.messages[:condition]
      end

      test "regex custom field is not valid without help message" do
        regex_exp = Desk::Ticket::Field::Regex.new(condition: "/d", help_message: "", ticket_field: @field)

        assert_not regex_exp.valid?

        assert_equal ["can't be blank"], regex_exp.errors.messages[:help_message]
      end
    end
  end
end
