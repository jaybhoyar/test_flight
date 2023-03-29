# frozen_string_literal: true

class Desk::Macro::DeletionService
  attr_reader :response
  attr_accessor :macros, :errors

  def initialize(macros)
    @macros = macros
    @number_of_macros = macros.count
    self.errors = []
  end

  def process
    ActiveRecord::Base.transaction do
      macros.each do |macro|
        macro.destroy
        set_errors(macro)
      end
    end

    create_service_response
  end

  def success?
    errors.empty?
  end

  private

    def set_errors(macros)
      if macros.errors.any?
        errors.push(macros.errors.full_messages.to_sentence)
      end
    end

    def create_service_response
      if errors.empty?
        @response = "#{@number_of_macros == 1 ? "Canned response has" : "Canned responses have"} been successfully deleted."
      end
    end
end
