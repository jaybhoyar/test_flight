# frozen_string_literal: true

class Desk::Groups::DeletionService
  attr_reader :response
  attr_accessor :groups, :errors

  def initialize(groups)
    @groups = groups
    @errors = []
  end

  def process
    Group.transaction do
      groups.each do |group|
        group.destroy
        set_errors(group)
      end
    end

    create_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(record)
      if record.errors.any?
        @errors = errors + record.errors.full_messages
      end
    end

    def create_service_response
      if errors.empty?
        @response = "#{groups.length == 1 ? "Group has" : "Groups have"} been successfully deleted!"
      end
    end
end
