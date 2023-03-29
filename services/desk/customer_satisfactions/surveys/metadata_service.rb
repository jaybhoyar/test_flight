# frozen_string_literal: true

class Desk::CustomerSatisfactions::Surveys::MetadataService
  def process
    {
      pointScaleOptions: get_options_for_point_scales,
      scaleChoiceOptions: Desk::CustomerSatisfaction::ScaleChoice::ALLOWED_POINT_SCALE_CHOICES,
      emailStateOptions: get_options_for_email_state
    }
  end

  private

    def get_options_for_point_scales
      Desk::CustomerSatisfaction::Question::ALLOWED_POINT_SCALES.map do |point_scale|
        { label: point_scale, value: point_scale }
      end
    end

    def get_options_for_email_state
      Desk::CustomerSatisfaction::Survey.email_states.map do |value, label|
        { label:, value: }
      end
    end
end
