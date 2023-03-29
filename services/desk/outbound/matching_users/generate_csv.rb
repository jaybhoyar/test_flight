# frozen_string_literal: true

require "csv"
class Desk::Outbound::MatchingUsers::GenerateCsv
  HEADER_ROW = ["Name", "Email"]

  attr_reader :users

  def initialize(users)
    @users = users
  end

  def process
    ::CSV.generate do |csv|
      csv << HEADER_ROW
      users.each do |user|
        csv << [user.name, get_email_contact_details(user)]
      end
    end
  end

  private

    def get_email_contact_details(user)
      if user.has_active_email_subscription?
        user.email_contact_details.pluck(:value).join(", ")
      end
    end
end
