# frozen_string_literal: true

class OnboardingStatesController < ApplicationController
  def update
    @organization.update!(organization_params)

    render status: :ok, json: { notice: "Onboarding state has been successfully updated." }
  end

  private

    def organization_params
      params.require(:organization).permit(:is_onboard)
    end
end
