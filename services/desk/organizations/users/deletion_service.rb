# frozen_string_literal: true

class Desk::Organizations::Users::DeletionService
  attr_reader :response
  attr_accessor :users, :errors

  def initialize(users)
    @users = users
    @total_count = users.size
    self.errors = []
  end

  def process
    begin
      ::User.transaction do
        users.each do |user|
          user.destroy
          set_errors(user)
        end
      end

      create_service_response

    rescue ActiveRecord::RecordInvalid => invalid
      set_errors(invalid.record)
      false
    end
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(record)
      if record.errors.any?
        errors.push(record.errors.full_messages.to_sentence)
      end
    end

    def create_service_response
      if errors.empty?
        @response = I18n.t("notice.common", resource: "Agent", action: "removed", count: @total_count)
      end
    end
end
