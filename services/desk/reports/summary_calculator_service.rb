# frozen_string_literal: true

class Desk::Reports::SummaryCalculatorService
  attr_reader :list, :keys

  def initialize(list, keys)
    @list = list
    @keys = keys
  end

  def get
    keys.inject({}) do |h, key|
      h[key] = get_summary(key)
      h
    end
  end

  def get_summary(key)
    summarised_data = ["present", "previous"].inject({}) do |h, key_name|
      h[key_name] = average(pluck(pluck(list, key), key_name))
      h
    end

    Desk::Reports::ValueChangeCalculatorService.new(summarised_data["present"], summarised_data["previous"]).get
  end

  def pluck(list, key)
    list.map { |x| x[key] }
  end

  def average(values)
    my_values = values.compact

    (my_values.sum / my_values.size.to_f).round(2)
  end
end
