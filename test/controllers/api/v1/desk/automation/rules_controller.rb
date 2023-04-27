# frozen_string_literal: true

class Api::V1::Desk::Automation::RulesController < Api::V1::BaseController
  before_action :load_rule, only: [:update, :destroy, :show]

  before_action :ensure_access_to_manage_automation_rules!, only: [:create, :update, :destroy]

  def index
    @rules = @organization.rules
      .includes(:recently_modified_tickets, :recent_executions)
      .page(params[:page_index])
      .per(params[:limit])

    @total_count = @organization.rules.count
  end

  def create
    automation_rule = @organization.rules.new(rule_params)
    add_attachments(automation_rule)
    if automation_rule.save
      render json: { notice: "Rule has been created." }, status: :ok
    else
      render json: { errors: automation_rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    @execution_log_entries = @automation_rule.execution_log_entries.order(created_at: :desc).limit(10)
    render
  end

  def update
    if @automation_rule.update(rule_params)
      add_attachments(@automation_rule)
      render json: { notice: "Rule has been updated." }, status: :ok
    else
      render json: { errors: @automation_rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @automation_rule.destroy
      render status: :ok, json: { notice: "Rule has been deleted." }
    else
      render status: :unprocessable_entity, json: { errors: @automation_rule.errors.full_messages }
    end
  end

  private

    def rule_params
      params.require(:rule).permit(
        :id, :name, :description, :active, :performer, :page_index, :limit,
        events_attributes: [ :id, :name, :_destroy ],
        condition_groups_attributes: [
          :id, :join_type, :conditions_join_type, :_destroy,
          conditions_attributes: [
            :id, :join_type, :field, :verb, :value, :kind,
            :_destroy, tag_ids: []
          ]
        ],
        actions_attributes: [
          :id, :name, :status, :body, :value, :_destroy,
          :actionable_id, :actionable_type, tag_ids: []
        ]
      )
    end

    def rule_params_attachments
      params.require(:rule).permit(
        :id, :name, :description, :active, :performer, :page_index, :limit,
        events_attributes: [ :id, :name, :_destroy ],
        condition_groups_attributes: [
          :id, :join_type, :conditions_join_type, :_destroy,
          conditions_attributes: [
            :id, :join_type, :field, :verb, :value, :kind,
            :_destroy, tag_ids: []
          ]
        ],
        actions_attributes: [
          :id, :name, :status, :body, :value, :_destroy,
          :actionable_id, :actionable_type, tag_ids: [], attachments: []
        ]
      )
    end

    def add_attachments(automation_rule)
      if rule_params_attachments[:actions_attributes]
        rule_params_attachments[:actions_attributes].each.with_index do |action, index|
          if action[:attachments]
            action[:attachments].each do |attachment|
              if attachment.is_a? String
                automation_rule.actions[index].attachments.attach(attachment)
              end
            end
          end
        end
      end
    end

    def load_rule
      @automation_rule = @organization.rules.find(params[:id])
    end
end
