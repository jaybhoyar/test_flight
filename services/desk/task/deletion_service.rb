# frozen_string_literal: true

class Desk::Task::DeletionService
  attr_reader :response, :task_lists, :errors

  def initialize(task_lists)
    @lists = task_lists
    @lists_length = task_lists.count
    @errors = []
  end

  def process
    ::Desk::Task::List.transaction do
      @lists.each do |list|
        set_errors(list) unless list.destroy
      end
    end
  end

  def status
    @errors.empty? ? :ok : :unprocessable_entity
  end

  def response
    if errors.empty?
      { notice: "#{@lists_length == 1 ? "List has" : "Lists have"} been successfully deleted." }
    else
      { errors: @errors }
    end
  end

  private

    def list_ids
      @_list_ids ||= @lists.pluck(:id)
    end

    def set_errors(record)
      if record.errors.any?
        @errors << record.errors.full_messages.to_sentence
      end
    end
end
