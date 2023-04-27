# frozen_string_literal: true

class Api::Mobile::V1::ProfileController < Api::V1::BaseController
  before_action :load_user_attributes

  def user_details
    @user = current_user
  end

  private

    def load_user_attributes
      @profile_attributes = UserProfileCarrier.new(current_user, @organization)
    end
end
