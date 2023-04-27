# frozen_string_literal: true

class Api::V1::Admin::Users::ActivationsController < Api::V1::BaseController
  before_action :load_user!

  def create
    if peform_action!
      render json: {
        notice: "#{@user.name}'s account has been #{@user.active? ? "activated" : "deactivated"}."
      }, status: :ok
    else
      render json: { errors: @errors }, status: :unprocessable_entity
    end
  end

  private

    def load_user!
      @user = User.find_by!(id: params[:team_id], organization: @organization)
    end

    def user_params
      params.require(:user).permit(:status)
    end

    def peform_action!
      if user_params[:status] == "activate"
        update_user_status("activate")
      else
        if has_other_admins?
          update_user_status("deactivate")
        else
          @user.errors.add(:base, "You cannot deactivate active admin from the organization!")
          @errors = @user.errors.full_messages
          false
        end
      end
    end

    def update_user_status(status)
      record_saved = if status == "activate"
        @user.activate!
      else
        @user.deactivate!
      end

      @errors = record_saved ? [] : @user.errors.full_messages
      @errors.empty?
    end

    def has_other_admins?
      @organization.admins.only_active.where.not(id: @user.id).exists?
    end
end
