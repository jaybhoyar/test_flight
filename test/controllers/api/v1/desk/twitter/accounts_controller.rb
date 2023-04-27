# frozen_string_literal: true

class Api::V1::Desk::Twitter::AccountsController < Api::V1::BaseController
  before_action :load_twitter_account, only: [:destroy, :show, :update]
  before_action :load_groups, only: [:show]

  def index
    @twitter_accounts = @organization.twitter_accounts.active
  end

  def destroy
    if @twitter_account.unsubscribe
      @twitter_account.destroy
      render json: { notice: "Account has been successfully unlinked." }, status: :ok
    else
      render json: { errors: @twitter_account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    render
  end

  def update
    if @twitter_account.update(twitter_account_params)
      render json: { notice: "Twitter preferences have been successfully updated." }, status: :ok
    else
      render json: { errors: @twitter_account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def load_twitter_account
      @twitter_account = @organization.twitter_accounts.find(params[:id])
    end

    def load_groups
      @groups = @organization.groups
    end

    def twitter_account_params
      params.require(:account).permit(:id, :convert_dm_into_ticket)
    end
end
