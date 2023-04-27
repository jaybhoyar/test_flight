# frozen_string_literal: true

class Api::V1::Desk::Task::DependenciesController < Api::V1::BaseController
  def index
    @task_list = @organization.task_lists
      .includes(actions: :rule)
      .find(params[:list_id])
  end
end
