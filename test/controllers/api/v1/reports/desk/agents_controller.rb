# frozen_string_literal: true

class Api::V1::Reports::Desk::AgentsController < Api::V1::Reports::BaseController
  before_action :ensure_access_to_view_reports!

  def index
    if filter_by_agents?
      @agent_response_times =
        get_data_filtered_by_agent_ids(@start_date, @end_date, agent_ids)
      @agent_response_times_previous_period =
        get_data_filtered_by_agent_ids(@previous_start_date, @previous_end_date, agent_ids)
    else
      @agent_response_times = get_data(@start_date, @end_date)
      @agent_response_times_previous_period = get_data(@previous_start_date, @previous_end_date)
    end

    render json: { members:, summary: }
  end

  private

    def select
      <<~SQL
        users.id as id,
        users.email as email,
        concat(users.first_name, ' ', users.last_name) as agent_name,
        round(avg(first_response_time)::numeric, 2)::float as avg_response_time,
        round(avg(resolution_time)::numeric, 2)::float as avg_resolution_time,
        count(ticket_id) as tickets_count,
        count(resolution_time) as resolved_tickets_count
      SQL
    end

    def format_output(agent_response_times)
      agent_response_times.to_a.map { |x| formatted_value(x) }
    end

    def convert_to_hash(agent_response_times)
      agent_response_times.inject({}) do |h, x|
        h[x.id] = {
          "email" => x.email,
          "name" => x.agent_name,
          "first_response_time" => x.avg_response_time,
          "resolution_time" => x.avg_resolution_time,
          "assigned" => x.tickets_count,
          "resolved" => x.resolved_tickets_count
        }
        h
      end
    end

    def previous_value(id, name)
      (@agent_response_times_previous_period[id] || {})[name]
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

      { "id" => id, "name" => obj[1]["name"].presence || obj[1]["email"] }.merge(value_hash)
    end

    def get_data_filtered_by_agent_ids(start_date, end_date, agent_ids)
      convert_to_hash(
        Desk::Ticket::ResponseTime
          .joins(ticket: :agent)
          .group("users.id")
          .select(select)
          .having("avg(first_response_time) > 0")
          .where("tickets.agent_id in (?)", agent_ids)
          .where("tickets.organization_id": @organization.id)
          .where("tickets.created_at": start_date..end_date)
          .order("avg_response_time")
      )
    end

    def get_data(start_date, end_date)
      convert_to_hash(
        Desk::Ticket::ResponseTime
          .joins(ticket: :agent)
          .group("users.id")
          .select(select)
          .having("avg(first_response_time) > 0")
          .where("tickets.organization_id": @organization.id)
          .where("tickets.created_at": start_date..end_date)
          .order("avg_response_time")
      )
    end

    def value_names
      @_value_names ||= ["first_response_time", "resolution_time", "assigned", "resolved"]
    end

    def members
      @_members = format_output(@agent_response_times)
    end

    def summary
      @_summary ||= Desk::Reports::SummaryCalculatorService.new(members, value_names).get
    end
end
