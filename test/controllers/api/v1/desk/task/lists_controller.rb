# frozen_string_literal: true

class Api::V1::Desk::Task::ListsController < Api::V1::BaseController
  before_action :load_task_list!, only: [:show, :update, :destroy]

  def index
    @lists = @organization.task_lists
    @lists = apply_search_filter_for(@lists) if params[:search_term].present?
  end

  def create
    list = @organization.task_lists.new(list_params)

    if list.save
      render json: {
        list:,
        notice: "Tasks list has been successfully created."
      }, status: :ok
    else
      render json: { errors: list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    @tasks = @list.items
    @tasks = apply_search_filter_for(@tasks) if params[:search_term].present?
  end

  def update
    if @list.update(list_params)
      render json: {
        list: @list,
        notice: response_message
      }, status: :ok
    else
      render json: { errors: @list.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @list.destroy
      render json: {
        notice: I18n.t("resource.delete", resource_name: "Tasks list")
      }, status: :ok
    else
      render json: {
        errors: full_messages_with_keys_for(list.errors)
      }, status: :unprocessable_entity
    end
  end

  def destroy_multiple
    @task_lists = @organization.task_lists.where!(id: params[:list][:ids])
    if !@task_lists.blank?
      lists_deletion_service = Desk::Task::DeletionService.new(@task_lists)
      lists_deletion_service.process
      render status: lists_deletion_service.status, json: lists_deletion_service.response
    else
      render status: :not_found, json: { errors: "Record not found!" }
    end
  end

  private

    def list_params
      params.require(:list).permit(
        :id, :name,
        items_attributes: [:id, :name, :info, :sequence, :_destroy]
      )
    end

    def load_task_list!
      @list = @organization.task_lists.find(params[:id])
    end

    def response_message
      deleted_items = list_params[:items_attributes] &&
                      list_params[:items_attributes].select { |attribute| attribute[:_destroy] }

      if deleted_items
        return I18n.t("tasks", count: deleted_items.length)
      end

      "Tasks list has been successfully updated."
    end

    def apply_search_filter_for(items)
      items.where("name ILIKE ?", "%#{params[:search_term]}%")
    end
end
