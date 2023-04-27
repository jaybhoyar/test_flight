# frozen_string_literal: true

class Api::V1::Reports::Desk::GroupsController < Api::V1::Reports::BaseController
  before_action :ensure_access_to_view_reports!

  def index
    if filter_by_groups?
      @group_response_times =
        get_data_filtered_by_group_ids(@start_date, @end_date, group_ids)
      @group_response_times_previous_period =
        get_data_filtered_by_group_ids(@previous_start_date, @previous_end_date, group_ids)
    else
      @group_response_times = get_data(@start_date, @end_date)
      @group_response_times_previous_period = get_data(@previous_start_date, @previous_end_date)
    end

    render json: { teams: format_output(@group_response_times), summary: }
  end

  private

    def select
      <<~SQL
        groups.id as id,
        groups.name as group_name,
        round(avg(first_response_time)::numeric, 2)::float as avg_response_time,
        round(avg(resolution_time)::numeric, 2)::float as avg_resolution_time,
        count(ticket_id) as tickets_count,
        count(resolution_time) as resolved_tickets_count
      SQL
    end

    def format_output(group_response_times)
      group_response_times.to_a.map { |x| formatted_value(x) }
    end

    def convert_to_hash(group_response_times)
      group_response_times.inject({}) do |h, x|
        h[x.id] = {
          "name" => x.group_name,
          "first_response_time" => x.avg_response_time,
          "resolution_time" => x.avg_resolution_time,
          "assigned" => x.tickets_count,
          "resolved" => x.resolved_tickets_count
        }
        h
      end
    end

    def previous_value(id, name)
      (@group_response_times_previous_period[id] || {})[name]
    end

    def formatted_value(obj)
      id = obj[0]

      value_hash = value_names.inject({}) do |h, value_name|
        present_value = obj[1][value_name]
        h[value_name] = Desk::Reports::ValueChangeCalculatorService
          .new(present_value, previous_value(id, value_name))
          .get

        h
      end

      { "id" => id, "name" => obj[1]["name"] }.merge(value_hash)
    end

    def get_data_filtered_by_group_ids(start_date, end_date, group_ids)
      convert_to_hash(
        Desk::Ticket::ResponseTime
          .joins(ticket: :group).group("groups.id")
          .select(select).having("avg(first_response_time) > 0")
          .where("tickets.group_id in (?)", group_ids)
          .where("tickets.organization_id": @organization.id)
          .where("tickets.created_at": start_date..end_date)
          .order("avg_response_time")
      )
    end

    def get_data(start_date, end_date)
      convert_to_hash(
        Desk::Ticket::ResponseTime
          .joins(ticket: :group).group("groups.id")
          .select(select).having("avg(first_response_time) > 0")
          .where("tickets.organization_id": @organization.id)
          .where("tickets.created_at": start_date..end_date)
          .order("avg_response_time")
      )
    end

    def value_names
      @_value_names ||= ["first_response_time", "resolution_time", "assigned", "resolved"]
    end

    def groups
      @_groups = format_output(@group_response_times)
    end

    def summary
      @_summary ||= Desk::Reports::SummaryCalculatorService.new(groups, value_names).get
    end
end
