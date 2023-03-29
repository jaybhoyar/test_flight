# frozen_string_literal: true

class Desk::Tasks::ActivityTrackerService
  TRACK_CHANGES_FOR_COLUMNS = {
    status: { type: "attribute" },
    name: { type: "attribute" }
  }.freeze

  ACTION_KEYS = {
    create: "activity.ticket.tasks.create",
    update: "activity.ticket.tasks.update",
    delete: "activity.ticket.tasks.delete",
    sub_ticket: "activity.ticket.tasks.sub_ticket"
  }.freeze

  attr_reader :task, :action

  def initialize(task, action)
    @task = task
    @action = action
  end

  def process
    case action
    when "create"
      log_task_create_activity!
    when "update"
      log_task_update_activity!
    when "sub_ticket"
      log_sub_ticket_create_activity!
    when "delete"
      log_task_delete_activity!
    end
  end

  private

    def log_task_create_activity!
      log_activity!(ACTION_KEYS[:create], I18n.t(ACTION_KEYS[:create], name: task.name))
    end

    def log_sub_ticket_create_activity!
      action = I18n.t(ACTION_KEYS[:sub_ticket], ticket_number: task.converted_ticket.number, name: task.name)
      log_activity!(ACTION_KEYS[:sub_ticket], action)
    end

    def log_task_update_activity!
      TRACK_CHANGES_FOR_COLUMNS.each do |column_name, _options|
        if task.send("saved_change_to_#{column_name}?")
          old_value, new_value = task.send("saved_change_to_#{column_name}")

          action_values = {
            old_value: format_value(old_value, column_name),
            new_value: format_value(new_value, column_name),
            name: task.name
          }

          key = "#{ACTION_KEYS[:update]}.#{column_name}"
          action = I18n.t(key, **action_values)
          log_activity!(key, action, action_values)
        end
      end
    end

    def log_task_delete_activity!
      log_activity!(ACTION_KEYS[:delete], I18n.t(ACTION_KEYS[:delete], name: task.name))
    end

    def log_activity!(key, action, options = {})
      owner = options[:owner] || user
      Activity.create!(
        key:,
        action:,
        owner:,
        old_value: options[:old_value],
        new_value: options[:new_value],
        trackable_id: task.ticket_id,
        trackable_type: "Ticket"
      )
    end

    def format_value(value, column_name)
      column_name == :status ? value.to_s.humanize : value
    end

    def user
      @_user ||= User.current
    end
end
