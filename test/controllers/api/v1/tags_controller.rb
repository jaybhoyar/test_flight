# frozen_string_literal: true

class Api::V1::TagsController < Api::V1::BaseController
  include ValidateTagsOrderable

  before_action -> { validate_tag_order_by(Tag) }, only: :index
  before_action :find_tag!, only: [:update, :show]
  before_action :find_tags!, only: :destroy_multiple

  def index
    @tags = if params[:search_string].present?
      tags.filter_by_name(params[:search_string])
    else
      tags
    end

    @total_count = @tags.length
    @tags = apply_order(@tags)
    @tags = @tags.page(page_index).per(per_page)
  end

  def show
    render
  end

  def create
    @tag = tags.new(tag_params)
    if @tag.save
      render
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @tag.update(tag_params)
      render
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy_multiple
    service = Tags::DeletionService.new(@tags)
    service.process

    if service.success?
      render json: { notice: service.response }, status: :ok
    else
      render json: { errors: service.errors }, status: :unprocessable_entity
    end
  end

  private

    def find_tag!
      @tag = tags.find_by!(id: params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end

    def find_tags!
      @tags = tags.where!(id: params[:tag][:ids]).includes(:taggings)
    end

    def per_page
      params[:limit] || 15
    end

    def page_index
      params[:page_index] || 1
    end

    def apply_order(tags)
      if params[:column] == "taggings_count"
        tags
          .left_joins(:taggings)
          .group(:id)
          .order("COUNT(taggings.id) #{params[:direction]}")
      else
        tags.order(params[:column] => params[:direction])
      end
    end
end
