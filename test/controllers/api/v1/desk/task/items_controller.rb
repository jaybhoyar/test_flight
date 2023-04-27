# frozen_string_literal: true

class Api::V1::Desk::Task::ItemsController < Api::V1::BaseController
  before_action :load_task_list!

  def create
    item = @list.items.new(item_params)

    if item.save
      render json: {
        item:,
        notice: "Task has been successfully created."
      }, status: :ok
    else
      render json: {
        errors: item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    item = @list.items.find(params[:id])

    if item.update(item_params)
      render json: {
        item:,
        notice: "Task has been successfully updated."
      }, status: :ok
    else
      render json: {
        errors: item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

    def item_params
      params.require(:item).permit(:id, :name, :info, :sequence, :list_id)
    end

    def load_task_list!
      @list = @organization.task_lists.find(item_params[:list_id])
    end
end
