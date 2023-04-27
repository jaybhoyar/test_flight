# frozen_string_literal: true

class Api::V1::Desk::Tickets::DefaultViewsController < Api::V1::BaseController
  before_action :load_ticket_view_carrier, only: :index

  def index
    @views = load_custom_views
  end

  private

    def load_ticket_view_carrier
      @ticket_view_carrier = Tickets::ViewCarrier.new(@organization, current_user)
    end

    def load_custom_views
      @organization.views.includes(:record_visibility, :creator, { rule: :organization }).active.select do |view|
        view.visible_to_user?(current_user)
      end
    end
end
