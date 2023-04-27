# frozen_string_literal: true

class Desk::CustomerSatisfactions::SurveyResponsesController < ApplicationController
  skip_before_action :load_organization
  before_action :initialize_update_scale_choice_service, only: :update

  def update
    if @survey_response_update_scale_choice_service.process
      redirect_to desk_survey_response_acknowledge_path(@survey_response_update_scale_choice_service.survey_response)
    end
  end

  private

    def initialize_update_scale_choice_service
      @survey_response_update_scale_choice_service =
        Desk::CustomerSatisfactions::SurveyResponses::UpdateScaleChoiceService.new(params)
    end
end
