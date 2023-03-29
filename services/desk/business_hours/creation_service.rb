# frozen_string_literal: true

class Desk::BusinessHours::CreationService
  FROM_TIME = Time.zone.parse("9:00 am")
  TO_TIME = Time.zone.parse("6:00 pm")
  WORKING_DAYS = %w(Monday Tuesday Wednesday Thursday Friday)

  attr_reader :business_hour

  def process
    @business_hour = ::Desk::BusinessHour.new
    initialize_schedules
    business_hour
  end

  def find_and_create_schedules(id)
    @business_hour = ::Desk::BusinessHour.find_by!(id:)
    create_schedules
  end

  private

    def initialize_schedules
      WORKING_DAYS.each { |day| business_hour.schedules.new(attributes(day)) }
    end

    def create_schedules
      WORKING_DAYS.each { |day| business_hour.schedules.create(attributes(day)) }
    end

    def attributes(day)
      {
        from: FROM_TIME,
        to: TO_TIME,
        day:,
        status: "active"
      }
    end
end
