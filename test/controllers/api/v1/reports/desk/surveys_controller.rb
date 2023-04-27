# frozen_string_literal: true

class Api::V1::Reports::Desk::SurveysController < Api::V1::Reports::BaseController
  before_action :ensure_access_to_view_reports!

  def index
    render json: { surveys: }
  end

  private

    def surveys
      @organization.customer_satisfaction_surveys
        .joins(scale_choices: :survey_responses)
        .where("desk_customer_satisfaction_survey_responses.created_at": @start_date..@end_date)
        .distinct
        .map do |survey|

        {
          "id" => survey.id,
          "name" => survey.name,
          "question" => survey.questions.first.text,
          "choices" => get_choices_data(survey)
        }
      end
    end

    def get_choices_data(survey)
      Desk::CustomerSatisfaction::SurveyResponse
        .joins(scale_choice: { question: :survey })
        .select(
          "desk_customer_satisfaction_scale_choices.id as choice_id,
          desk_customer_satisfaction_scale_choices.text as name,
          count(scale_choice_id) as count,
          desk_customer_satisfaction_scale_choices.slug as slug"
        )
        .where("desk_customer_satisfaction_questions.survey_id = ?", survey.id)
        .where("desk_customer_satisfaction_survey_responses.created_at": @start_date..@end_date)
        .group("desk_customer_satisfaction_scale_choices.id")
        .order("desk_customer_satisfaction_scale_choices.text")
        .map { |row| row.slice("name", "count", "slug") }
    end
end
