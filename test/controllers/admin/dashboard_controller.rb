# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  include SSOHelpers
  before_action :enforce_onboarding_flow!

  def index
    render
  end

  private

    def enforce_onboarding_flow!
      if revisiting_complete_onboarding?
        redirect_to root_url
      elsif enforce_onboarding?
        redirect_to "/desk/onboarding"
      end
    end

    def enforce_onboarding?
      !onboarding_path? && !@organization.is_onboard?
    end

    def revisiting_complete_onboarding?
      onboarding_path? && @organization.is_onboard?
    end

    def onboarding_path?
      params[:path].include? "desk/onboarding"
    end

    def app_secrets
      Rails.application.secrets
    end
end
