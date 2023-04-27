# frozen_string_literal: true

require "test_helper"

module Desk
  module Ticket
    class Field::OptionTest < ActiveSupport::TestCase
      test "that custom field option is valid" do
        option = build :ticket_field_option
        assert option.valid?
      end

      test "that custom field option is not valid without attributes" do
        option = build :ticket_field_option, name: nil
        assert_not option.valid?
      end

      test "that custom field option is not valid with existing name" do
        field = create :ticket_field, :dropdown
        option1 = create :ticket_field_option, name: "Mumbai", ticket_field: field
        option2 = build :ticket_field_option, name: "Mumbai", ticket_field: field
        assert_not option2.valid?
      end

      test "that custom field option with existing name is valid for different field" do
        option1 = create :ticket_field_option, name: "Mumbai"
        option2 = build :ticket_field_option, name: "Mumbai"
        assert option2.valid?
      end
    end
  end
end
