# frozen_string_literal: true

module Desk::Ticketing
  module Tasks
    class CreateMultipleService
      attr_accessor :ticket, :options, :response, :tasks

      def initialize(ticket, options)
        @options = options
        @ticket = ticket
        @tasks = []
      end

      def process
        create_tasks
        create_service_response
      end

      private

        def create_tasks
          options[:tasks].each do |task_params|
            task = ticket.tasks.new(name: task_params[:name])
            @tasks << task if task.save
          end
        end

        def create_service_response
          @response = "#{plural_tasks_str} has been successfully added."
        end

        def plural_tasks_str
          ActionController::Base.helpers.pluralize(tasks.size, "task was", plural: "tasks were")
        end
    end
  end
end
