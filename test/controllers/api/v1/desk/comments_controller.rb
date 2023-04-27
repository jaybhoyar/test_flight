# frozen_string_literal: true

class Api::V1::Desk::CommentsController < Api::V1::BaseController
  before_action :load_ticket!, only: [:create]
  before_action :assign_comment_author, only: [:create]
  before_action :load_comment!, only: [:update, :destroy]

  before_action :ensure_access_to_view_tickets!, only: :index
  before_action :ensure_access_to_manage_tickets!, only: [:create, :update, :destroy]

  def index
    unless params[:comment] && params[:comment][:filter_by]
      return render json: {
        errors: ["Insufficient parameters received"]
      }, status: :bad_request
    end

    @comments = Desk::Ticket::Comment::Filter::FilterService.new(
      @organization,
      comment_filter_params).process
  end

  def create
    @comment = Desk::Ticket::Comment::CreateService.new(@ticket, comment_params).process

    if @comment.valid?
      render
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @comment.update(comment_params)
      add_attachments
      render
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @comment.destroy
      render json: { notice: "#{@comment.comment_type.capitalize} has been successfully deleted." }, status: :ok
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def comment_params
      @_comment_params ||= params.require(:comment).permit(
        :info,
        :author_id,
        :comment_type,
        :channel_mode,
        attachments: [],
        forward_emails_attributes: [:email, :delivery_type]
      )
    end

    def assign_comment_author
      unless comment_params[:author_id]
        comment_params.merge!(author_type: "User", author: current_user)
      end
    end

    def load_ticket!
      @ticket = @organization.tickets.find_by!(id: params[:ticket_id])
    end

    def load_comment!
      @comment = Comment.find_by!(id: params[:id])
    end

    def add_attachments
      if comment_params[:attachments]
        comment_params[:attachments].each do |attachment|
          @comment.attach(attachment)
        end
      end
    end

    def comment_filter_params
      params.require(:comment).permit(
        filter_by: [:node, :rule, :value]
      )
    end
end
