# frozen_string_literal: true

module ErrorHandlers
  extend ::ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid do |e|
      render_unprocessable_entity(e.record.errors.full_messages)
    end
  end

  def render_unauthorized(err)
    render json: { errors: err }, status: :unauthorized
  end

  def render_bad_request(err)
    render json: { errors: err }, status: :bad_request
  end

  def render_unprocessable_entity(err)
    render json: { errors: err }, status: :unprocessable_entity
  end

  def render_not_found(err)
    render json: { errors: err }, status: :not_found
  end
end
