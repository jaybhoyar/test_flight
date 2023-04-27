# frozen_string_literal: true

class Api::V1::Desk::SettingsController < Api::V1::BaseController
  before_action :load_setting

  def show
    render
  end

  def update
    if @setting.update(setting_params)
      render "show"
    else
      render(status: :unprocessable_entity, json: { errors: @setting.errors.full_messages })
    end
  end

  private

    def load_setting
      @setting = @organization.setting
    end

    def setting_params
      params.require(:setting).permit(
        :visibility,
        :base_url,
        :custom_authentication,
        :automatic_redaction,
        :pre_chat_question_visibility,
        :post_chat_question_visibility,
        :auto_bcc, :bcc_email,
        :tickets_email_footer,
        :tickets_email_footer_content
      )
    end
end
