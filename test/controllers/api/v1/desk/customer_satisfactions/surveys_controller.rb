# frozen_string_literal: true

class Api::V1::Desk::CustomerSatisfactions::SurveysController < Api::V1::BaseController
  before_action :load_survey!, only: [:edit, :update, :destroy]
  before_action :load_surveys!, only: :destroy_multiple
  before_action :load_survey_carrier, only: [:edit, :new]

  def index
    get_surveys
  end

  def new
    render
  end

  def create
    create_customer_satisfaction_survey

    if @survey.valid?
      render status: :created, json: { notice: "Survey has been added successfully." }
    else
      render status: :unprocessable_entity, json: { errors: @survey.errors.full_messages }
    end
  end

  def edit
    render
  end

  def update
    survey_update_service = Desk::CustomerSatisfactions::Surveys::UpdateService.new(
      @organization,
      survey_params,
      @survey)

    if survey_update_service.process
      render status: :ok, json: { notice: "Survey has been updated successfully." }
    else
      render status: :unprocessable_entity, json: { errors: @survey.errors.full_messages }
    end
  end

  def destroy
    if @survey.destroy
      render status: :ok, json: { notice: "Survey has been deleted successfully." }
    else
      render status: :unprocessable_entity, json: { errors: @survey.errors.full_messages }
    end
  end

  def destroy_multiple
    service = Desk::CustomerSatisfactions::Surveys::DeletionService.new(@surveys)
    service.process

    if service.success?
      render status: :ok, json: { notice: service.response }
    else
      render status: :unprocessable_entity, json: { errors: service.errors }
    end
  end

  private

    def load_survey!
      @survey = @organization.customer_satisfaction_surveys.find_by!(id: params[:id])
    end

    def load_surveys!
      @surveys = @organization.customer_satisfaction_surveys.where!(id: params[:survey][:ids])
    end

    def load_survey_carrier
      @survey_carrier = CustomerSatisfactions::SurveyCarrier.new(@organization, @survey)
    end

    def create_customer_satisfaction_survey
      survey_create_service = Desk::CustomerSatisfactions::Surveys::CreateService.new(@organization, survey_params)
      survey_create_service.process

      @survey = survey_create_service.survey
    end

    def survey_params
      params.require(:survey).permit(
        :id, :name, :enabled, :email_state, :search_term, :page_index, :page_size,
        acknowledgement_attributes: [:id, :text, :comment, :feedback_response_text],
        questions_attributes: [
          :id, :text, :default, :display_order, :point_scale,
          scale_choices_attributes: [:id, :text, :display_order, :slug]
        ]
      )
    end

    def get_surveys
      @surveys = @organization.customer_satisfaction_surveys

      if search?
        @surveys = @surveys.where("name ilike ?", "%#{survey_params[:search_term]}%")
      end
      @total_count = @surveys.size
      @surveys = @surveys.includes(:questions, :acknowledgement).page(page_index).per(page_size)
    end

    def search?
      params[:survey] && params[:survey][:search_term].present?
    end

    def page_index
      params.dig(:survey, :page_index) || 1
    end

    def page_size
      params.dig(:survey, :page_size) || 15
    end
end
