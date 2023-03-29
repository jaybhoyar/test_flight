# frozen_string_literal: true

class Desk::Organizations::Seeder::CustomerSatisfactionSurveys
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def process!
    organization.customer_satisfaction_surveys.create!(survey_params)
  end

  private

    def survey_params
      {
        name: "Default Survey",
        enabled: false,
        default: true,
        email_state: "resolved_ticket",
        acknowledgement_attributes: {
          text: "Thank you. Your feedback has been submitted."
        },
        questions_attributes: [
          {
            text: "How would you rate your overall satisfaction for the resolution provided by the agent?",
            default: true,
            display_order: 1,
            point_scale: default_point_scale,
            scale_choices_attributes: scale_choice_params(default_point_scale)
          }
        ]
      }
    end

    def default_point_scale
      "3"
    end

    def scale_choice_params(point_scale)
      ::Desk::CustomerSatisfaction::ScaleChoice::ALLOWED_POINT_SCALE_CHOICES[point_scale]
        .map.with_index(1) do |scale_choice, display_order|

        {
          text: scale_choice,
          display_order:,
          slug: ::Desk::CustomerSatisfaction::ScaleChoice::ALLOWED_POINT_SCALE_CHOICE_SLUG[scale_choice]
        }
      end
    end
end
