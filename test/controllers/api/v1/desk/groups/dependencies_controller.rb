# frozen_string_literal: true

class Api::V1::Desk::Groups::DependenciesController < Api::V1::BaseController
  before_action :load_group!

  MODEL_NAME_KEYS_MAP = {
    "Desk::Macro::Rule" => "canned_responses",
    "Desk::Automation::Rule" => "rules",
    "View::Rule" => "views"
  }

  def index
    render json: { dependencies: }, status: :ok
  end

  private

    def load_group!
      @group = @organization.groups.find(params[:group_id])
    end

    def dependencies
      @dependencies_hash = {}

      @group.actions.includes(:rule).each do |action|
        build_object_for_a_record.call(action.rule)
      end

      @group.conditions.includes(conditionable: :rule).each do |action|
        conditionable = action.conditionable
        conditionable = conditionable.rule if conditionable.type == "Desk::Automation::ConditionGroup"

        build_object_for_a_record.call(conditionable)
      end

      @dependencies_hash
    end

    def build_object_for_a_record
      lambda do |obj|
        key = MODEL_NAME_KEYS_MAP[obj.type]
        values = @dependencies_hash[key] || []

        unless values.detect { |v| v[:id] == obj.id }
          values << { id: obj.id, name: obj.name }
          @dependencies_hash[key] = values
        end
      end
    end
end
