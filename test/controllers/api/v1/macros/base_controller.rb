# frozen_string_literal: true

class Api::V1::Macros::BaseController < Api::V1::BaseController
  include ValidateTagsOrderable

  before_action -> { validate_tag_order_by(Desk::Macro::Rule) }, only: :index
  before_action :load_macro!, only: [:show, :update]
  before_action :load_macros!, only: :destroy_multiple

  def index
    @macros = visible_macros
    if params[:search_string].present?
      @macros = @macros.filter_by_name(params[:search_string])
    end

    @macros = @macros.without_sequence_order.order(params[:column] => params[:direction])
  end

  def create
    @macro = macros_scope.new(macro_params)
    @macro.creator = current_user
    if @macro.save
      render status: :ok, json: { notice: "Canned response has been successfully created." }
    else
      render status: :unprocessable_entity, json: { errors: @macro.errors.full_messages }
    end
  end

  def show
    render
  end

  def update
    if @macro.update(macro_params)
      render status: :ok, json: { notice: "Canned response has been successfully updated." }
    else
      render status: :unprocessable_entity, json: { errors: @macro.errors.full_messages }
    end
  end

  def destroy_multiple
    service = Desk::Macro::DeletionService.new(@macros)
    service.process

    if service.success?
      render status: :ok, json: { notice: service.response }
    else
      render status: :unprocessable_entity, json: { error: service.errors }
    end
  end

  private

    def macros_scope
      @organization.desk_macros
    end

    def visible_macros
      macros_scope.visible(current_user)
    end

    def load_macro!
      @macro = visible_macros.find_by!(id: params[:id])
    end

    def load_macros!
      @macros = visible_macros
        .includes(:conditions, :attachments_attachments, :actions, record_visibility: :group_record_visibilities)
        .where!(id: params[:macro][:ids])
    end

    def macro_params
      params.require(:macro).permit(
        :id, :name, :description
      )
    end
end
