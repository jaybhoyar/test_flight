# frozen_string_literal: true

class Desk::CustomerSatisfactions::AcknowledgesController < ApplicationController
  before_action :load_survey_response!,
    :initialize_customer_satisfaction_acknowledge_carrier, only: :show

  def show
    render
  end

  private

    def load_survey_response!
      @survey_response = Desk::CustomerSatisfaction::SurveyResponse.find_by!(id: params[:survey_response_id])
    end

    def initialize_customer_satisfaction_acknowledge_carrier
      @acknowledge_carrier = CustomerSatisfactions::AcknowledgeCarrier.new(@survey_response)
    end
end
