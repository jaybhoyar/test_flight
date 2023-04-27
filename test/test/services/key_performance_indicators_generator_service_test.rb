# frozen_string_literal: true

require "test_helper"

class KeyPerformanceIndicatorsGeneratorServiceTest < ActiveSupport::TestCase
  def test_service_success
    data = generate_data

    assert_equal [
      :client_application_name,
      :organizations_data
    ], data.keys.sort
    assert_equal Organization.count, data[:organizations_data].count
    assert_equal "Desk", data[:client_application_name]
  end

  private

    def generate_data
      KeyPerformanceIndicatorsGeneratorService.new.process
    end
end
