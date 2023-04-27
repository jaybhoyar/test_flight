# frozen_string_literal: true

class Api::V1::Reports::Desk::TicketsController < Api::V1::Reports::BaseController
  before_action :ensure_access_to_view_reports!, only: :index

  def index
    if filter_by_agents?

      @ticket_status_changes =
        get_data_filtered_by_agent_ids(@start_date, @end_date, agent_ids)
      @ticket_status_changes_previous_period =
        get_data_filtered_by_agent_ids(@previous_start_date, @previous_end_date, agent_ids)

    elsif filter_by_groups?

      @ticket_status_changes =
        get_data_filtered_by_group_ids(@start_date, @end_date, group_ids)

      @ticket_status_changes_previous_period =
        get_data_filtered_by_group_ids(@previous_start_date, @previous_end_date, group_ids)

    else

      @ticket_status_changes =
        get_data(@start_date, @end_date)

      @ticket_status_changes_previous_period =
        get_data(@previous_start_date, @previous_end_date)

    end

    render json: { ticket_statuses: format_output(@ticket_status_changes) }
  end

  def time_series
    render json: { dates: time_series_dates, data: time_series_data }
  end

  private

    def time_series_dates
      @_time_series_date ||= (@start_date.to_date..@end_date.to_date).to_a.map(&:to_s)
    end

    def time_series_data
      [
        { "name" => "new", values: new_ticket_counts },
        { "name" => "resolved", values: resolved_ticket_counts }
      ]
    end

    def new_ticket_counts
      values = Desk::Ticket::StatusChange
        .select("date(desk_ticket_status_changes.created_at), count(desk_ticket_status_changes.status)")
        .joins(:ticket)
        .where("tickets.organization_id": @organization.id)
        .where(status: "new").group("date(desk_ticket_status_changes.created_at)")
        .map { |v| [v.date.to_s, v.count] }
        .to_h

      time_series_dates.map { |date| values[date] || 0 }
    end

    def resolved_ticket_counts
      values = Desk::Ticket::StatusChange
        .select("date(desk_ticket_status_changes.created_at), count(desk_ticket_status_changes.status)")
        .joins(:ticket)
        .where("tickets.organization_id": @organization.id)
        .where(status: "resolved").group("date(desk_ticket_status_changes.created_at)")
        .map { |v| [v.date.to_s, v.count] }
        .to_h

      time_series_dates.map { |date| values[date] || 0 }
    end

    def format_output(ticket_status_changes)
      ticket_status_changes.to_a.map { |x| formatted_value(x) }
    end

    def formatted_value(obj)
      name = obj[0]
      present_value = obj[1]

      value_hash = Desk::Reports::ValueChangeCalculatorService.new(present_value, previous_value(name)).get

      { "name" => name, "value" => value_hash }
    end

    def previous_value(name)
      @ticket_status_changes_previous_period[name]
    end

    def get_data_filtered_by_agent_ids(start_date, end_date, agent_ids)
      Desk::Ticket::StatusChange.joins(ticket: :organization)
        .where("tickets.organization_id": @organization.id)
        .where("tickets.agent_id in (?)", agent_ids)
        .where(created_at: start_date..end_date)
        .group("status").count
    end

    def get_data_filtered_by_group_ids(start_date, end_date, group_ids)
      Desk::Ticket::StatusChange.joins(ticket: :organization)
        .where("tickets.organization_id": @organization.id)
        .where("tickets.group_id in (?)", group_ids)
        .where(created_at: start_date..end_date)
        .group("status").count
    end

    def get_data(start_date, end_date)
      Desk::Ticket::StatusChange.joins(ticket: :organization)
        .where("tickets.organization_id": @organization.id)
        .where(created_at: start_date..end_date)
        .group("status").count
    end
end
