# frozen_string_literal: true

class Desk::Organizations::Users::FilterService
  attr_reader :users, :filter_params

  def initialize(users, filter_params)
    @users = users
    @filter_params = filter_params
  end

  def process
    return users if filter_params.empty?

    users = apply_status_filter

    if filter_params[:role_ids].present?
      users = users.where(organization_role_id: filter_params[:role_ids])
    end

    if filter_params[:group_ids].present?
      users = users
        .includes(:group_members)
        .where(
          group_members: { group_id: filter_params[:group_ids] }
        )
    end

    if filter_params[:available_for_desk].present?
      users = users.where(available_for_desk:)
    end
    users
  end

  private

    def apply_status_filter
      case filter_params[:status]
      when "active"
        users.only_active
      when "deactivated"
        users.only_inactive
      else
        users
      end
    end

    def available_for_desk
      filter_params[:available_for_desk] == "true"
    end
end
