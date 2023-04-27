# frozen_string_literal: true

class Api::V1::Desk::Macros::PreviewsController < Api::V1::BaseController
  before_action :load_macro!, only: :create
  before_action :load_ticket!, only: :create

  def create
    render
  end

  private

    def load_macro!
      @macro = @organization.desk_macros.find(params[:macro_id])
    end

    def load_ticket!
      @ticket = @organization.tickets.find(params[:ticket_id])
    end
end
