# frozen_string_literal: true

class Api::V1::Desk::CustomerSatisfactions::SurveyResponsesController < Api::V1::BaseController
  before_action :load_survey_response!, :load_organization, only: :update
  skip_before_action :authenticate_user_for_api, :authenticate_user_using_x_auth_token

  def update
    if @survey_response.update(survey_response_params)
      render status: :ok, json: carrier.react_component_props
    else
      render status: :unprocessable_entity, json: { errors: @survey_response.errors.full_messages }
    end
  end

  private

    def load_survey_response!
      @survey_response = Desk::CustomerSatisfaction::SurveyResponse.find_by!(id: params[:id])
    end

    def load_organization
      @organization = @survey_response.ticket.organization
    end

    def survey_response_params
      params.require(:survey_response).permit(:comment)
    end

    def carrier
      CustomerSatisfactions::AcknowledgeCarrier.new(@survey_response)
    end
end
