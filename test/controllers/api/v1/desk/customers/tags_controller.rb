# frozen_string_literal: true

class Api::V1::Desk::Customers::TagsController < Api::V1::TagsController
  before_action -> { validate_tag_order_by(Desk::Tag::CustomerTag) }, only: :index
  before_action :ensure_access_to_manage_customer_tags!, only: [:create, :update, :destroy_multiple]

  private

    def tags
      @_tags ||= @organization.customer_tags
    end
end
