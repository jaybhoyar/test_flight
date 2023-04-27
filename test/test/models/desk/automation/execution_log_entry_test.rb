# frozen_string_literal: true

require "test_helper"

module Desk
  module Automation
    class ExecutionLogEntryTest < ActiveSupport::TestCase
      test "valid record" do
        record = build :execution_log_entry
        assert record.valid?
      end
    end
  end
end
