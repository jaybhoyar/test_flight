# frozen_string_literal: true

module AssigneeFilterable
  extend ActiveSupport::Concern

  def filter_by_agents?
    assignee_type == "agent" && !agent_ids.empty?
  end

  def filter_by_groups?
    assignee_type == "group" && !agent_ids.empty?
  end

  def agent_ids
    (params[:assignee][:ids].is_a?(Array) ? params[:assignee][:ids] : []) rescue []
  end

  def group_ids
    agent_ids
  end

  def assignee_type
    params[:assignee][:type] rescue nil
  end
end
