# frozen_string_literal: true

class Api::V1::Desk::Tickets::ViewsController < Api::V1::BaseController
  before_action :set_view, only: [:show, :update, :destroy]
  before_action :load_views!, only: [:update_multiple, :destroy_multiple]

  def index
    @views = @organization.views
      .order(created_at: :desc)
      .select { |view|
        view.visible_to_user?(current_user)
      }
  end

  def show
    render
  end

  def create
    @view = @organization.views.new(view_params)
    @view.creator = current_user
    @view.rule.organization = @organization if @view.rule.present?
    if @view.save
      render json: { notice: "View has been successfully added." }, status: :ok
    else
      render json: { errors: @view.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @view.update(view_params)
      render json: { notice: "View has been successfully updated." }, status: :ok
    else
      render json: { errors: @view.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_multiple
    views_update_multiple_service = Desk::Views::UpdateMultipleService.new(@views, view_params)
    views_update_multiple_service.process

    if views_update_multiple_service.success?
      render json: { notice: views_update_multiple_service.response }, status: :ok
    else
      render json: { errors: views_update_multiple_service.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @view.destroy
      render json: { notice: "View has been successfully deleted." }, status: :ok
    else
      render json: { errors: @view.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy_multiple
    service = Desk::Views::DeletionService.new(@views)
    service.process

    if service.success?
      render status: :ok, json: { notice: service.response }
    else
      render status: :unprocessable_entity, json: { error: service.errors }
    end
  end

  private

    def view_params
      params.require(:view).permit(
        :id, :title, :description, :status, :sort_column, :sort_direction,
        record_visibility_attributes: [:id, :visibility, group_ids: [] ],
        rule_attributes: [:id, :name, :description, :_destroy,
          conditions_attributes: [:id, :join_type, :field, :kind, :verb, :value, :_destroy, :kind, tag_ids: []]
        ]
      )
    end

    def set_view
      @view = @organization.views.find(params[:id])
      authorize @view, :can_access_record?
    end

    def load_views!
      @views = @organization.views
        .includes(:creator, rule: [:organization, :conditions,
:attachments_attachments], record_visibility: :group_record_visibilities)
        .where!(id: params[:view][:ids])

      @views.each do |view|
        authorize view, :can_access_record?
      end
    end
end
