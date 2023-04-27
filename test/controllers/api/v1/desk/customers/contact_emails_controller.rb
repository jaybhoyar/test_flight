# frozen_string_literal: true

class Api::V1::Desk::Customers::ContactEmailsController < Api::V1::BaseController
  before_action :load_contact_email!, only: :destroy
  before_action :ensure_access_to_view_customer_details!, only: :index
  before_action :ensure_access_to_manage_customer_details!, only: :destroy

  def index
    @users = User.get_customers_details(@organization)
  end

  def destroy
    if @contact_email.destroy
      render json: { notice: "Email has been successfully removed." }, status: :ok
    else
      render json: { errors: @contact_email.errors.full_messages }, status: :unprocessable_entity
    end
  end

  protected

    def load_contact_email!
      @contact_email = ContactDetail.find_by!(id: params[:id])
    end
end
