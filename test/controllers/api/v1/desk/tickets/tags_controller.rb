# frozen_string_literal: true

class Api::V1::Desk::Tickets::TagsController < Api::V1::TagsController
  before_action -> { validate_tag_order_by(Desk::Tag::TicketTag) }, only: :index
  before_action :ensure_access_to_manage_ticket_tags!, only: [:create, :update, :destroy_multiple]

  def merge
    service = Desk::Tags::MergeService.new(@organization, merge_params)
    if service.errors.present?
      render_unprocessable_entity(service.errors)
    else
      service.merge

      render json: {
        notice: I18n.t("notice.generic.plural", resource: "Tags", action: "merged")
      }, status: :ok
    end
  end

  private

    def tags
      @_tags ||= @organization.ticket_tags
    end

    def merge_params
      params.require(:tags).permit(:primary_id, :secondry_id)
    end

    def apply_order(tags)
      if params[:column] == "taggings_count"
        tags
          .joins(taggings_join)
          .group(:id)
          .order("COUNT(tickets.id) #{params[:direction]}")
      else
        tags.order(params[:column] => params[:direction])
      end
    end

    def taggings_join
      arel_tags = Arel::Table.new(:tags)
      arel_taggings = Arel::Table.new(:taggings)
      arel_tickets = Arel::Table.new(:tickets)

      arel_tags
        .join(arel_taggings, Arel::Nodes::OuterJoin).on(
          arel_tags[:id].eq(arel_taggings[:tag_id])
        )
        .join(arel_tickets, Arel::Nodes::OuterJoin).on(
          arel_taggings[:taggable_type].eq("Ticket").and(
            arel_tickets[:id].eq(arel_taggings[:taggable_id])
          ).and(
            arel_tickets[:status].not_in([:closed, :spam, :trash])
          )
        )
        .join_sources
    end
end
