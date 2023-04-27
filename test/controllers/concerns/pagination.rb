# frozen_string_literal: true

module Pagination
  extend ActiveSupport::Concern

  included do
    def current_page
      page = params[:page].to_i
      page > 0 ? page : 1
    end

    def per_page_limit
      limit = params[:limit].to_i
      limit > 0 ? limit : 25
    end
  end
end
