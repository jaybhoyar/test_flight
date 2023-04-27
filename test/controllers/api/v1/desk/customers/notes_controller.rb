# frozen_string_literal: true

class Api::V1::Desk::Customers::NotesController < Api::V1::BaseController
  before_action :load_contact!
  before_action :load_note!, only: [:update, :destroy]
  before_action :add_agent, only: [:create, :update]

  before_action :ensure_access_to_view_customer_details!, only: :index
  before_action :ensure_access_to_manage_customer_details!, only: [:create, :update, :destroy]

  def index
    @notes = @customer.notes.order("updated_at DESC")
  end

  def update
    if @note.update(note_params)
      render json: { notice: "Note has been successfully updated." }, status: :ok
    else
      render_unprocessable_entity(@note.errors.full_messages)
    end
  end

  def create
    @note = @customer.notes.new(note_params)
    if @note.save
      render json: { notice: "Note has been successfully created." }, status: :ok
    else
      render_unprocessable_entity(@note.errors.full_messages)
    end
  end

  def destroy
    if @note.destroy
      render json: { notice: "Note has been successfully deleted." }, status: :ok
    else
      render_unprocessable_entity(@note.errors.full_messages)
    end
  end

  private

    def note_params
      params.require(:notes).permit(:description, :agent_id)
    end

    def add_agent
      params[:notes][:agent_id] = current_user.id
    end

    def load_contact!
      @customer = User.find_by!(id: params[:customer_id], organization: @organization)
    end

    def load_note!
      @note = @customer.notes.find_by!(id: params[:id])
    end
end
