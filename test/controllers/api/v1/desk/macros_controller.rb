# frozen_string_literal: true

class Api::V1::Desk::MacrosController < Api::V1::Macros::BaseController
  before_action :ensure_access_to_manage_desk_canned_responses!, only: [:create, :update, :destroy_multiple]

  private

    def macros_scope
      @organization.desk_macros
    end

    def macro_params
      params.require(:macro).permit(
        :id, :name, :description,
        actions_attributes: [
          :id, :name, :body, :value, :_destroy,
          :actionable_id, :actionable_type, tag_ids: []
        ],
        record_visibility_attributes: [
          :id, :visibility, group_ids: []
        ]
      )
    end
end
