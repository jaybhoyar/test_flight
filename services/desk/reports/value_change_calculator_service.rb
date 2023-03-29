# frozen_string_literal: true

class Desk::Reports::ValueChangeCalculatorService
  attr_reader :present_value, :previous_value, :change_percentage

  def initialize(present_value, previous_value)
    @present_value = present_value
    @previous_value = previous_value
    @change_percentage = nil
  end

  def get
    @change_percentage = calculate_change_percentage

    {
      "present" => present_value,
      "previous" => previous_value,
      "change_percentage" => @change_percentage
    }
  end

  def calculate_change_percentage
    if present_value.present? && previous_value.present?
      (((present_value - previous_value) / previous_value.to_f) * 100).round(2)
    end
  end
end
