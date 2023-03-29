# frozen_string_literal: true

class Desk::Outbound::DeliveryWindowService
  FROM_TIME = Time.zone.parse("9am")
  TO_TIME = Time.zone.parse("5pm")
  WORKING_DAYS = %(Monday Tuesday Wednesday Thursday Friday)
  DEFAULT_NAME = "Default"

  attr_reader :outbound_delivery_window

  def process
    @outbound_delivery_window = ::Outbound::DeliveryWindow.new(name: DEFAULT_NAME)
    initialize_schedules
    outbound_delivery_window
  end

  def find_and_create_schedules(id)
    @outbound_delivery_window = ::Outbound::DeliveryWindow.find_by(id:)
    create_schedules
  end

  private

    def initialize_schedules
      ::Outbound::DeliveryWindow::Schedule::DAYS_NAMES.each { |day|
 outbound_delivery_window.schedules.new(attributes(day)) }
    end

    def create_schedules
      ::Outbound::DeliveryWindow::Schedule::DAYS_NAMES.each { |day|
 outbound_delivery_window.schedules.create(attributes(day)) }
    end

    def attributes(day)
      {
        from: FROM_TIME,
        to: TO_TIME,
        day:,
        status: WORKING_DAYS.include?(day) ? "active" : "inactive"
      }
    end
end
