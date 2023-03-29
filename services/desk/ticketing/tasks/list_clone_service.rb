# frozen_string_literal: true

module Desk::Ticketing
  module Tasks
    class ListCloneService
      attr_accessor :task_list, :ticket, :errors, :response, :tasks

      def initialize(ticket, task_list)
        @task_list = task_list
        @ticket = ticket
        @errors = []
      end

      def process
        begin
          @tasks = clone_task_list_items!
          create_service_response
        rescue ActiveRecord::RecordInvalid => invalid
          set_errors(invalid.record)
        end
      end

      def success?
        errors.empty?
      end

      private

        def clone_task_list_items!
          ActiveRecord::Base.transaction do
            task_list.items.map do |item|
              ticket.tasks.create!(name: item.name, info: item.info)
            end
          end
        end

        def set_errors(task)
          if task.errors.any?
            errors.push(task.errors.full_messages.to_sentence)
          end
        end

        def create_service_response
          @response = @tasks.empty? ? "There are no tasks in the list." : "#{plural_tasks_str} been successfully added."
        end

        def plural_tasks_str
          ActionController::Base.helpers.pluralize(tasks.size, "task has", plural: "tasks have")
        end
    end
  end
end
