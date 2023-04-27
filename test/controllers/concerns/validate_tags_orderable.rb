# frozen_string_literal: true

module ValidateTagsOrderable
  extend ::ActiveSupport::Concern
  SORT_DIRECTION = ["ASC", "asc", "DESC", "desc"]

  def validate_tag_order_by(klass)
    validate_tag_column_name(klass)
    validate_order_direction
  end

  private

    def validate_tag_column_name(klass)
      params[:column] = if klass.column_names.include?(params[:column]) || params[:column] == "taggings_count"
        params[:column]
      else
        "created_at"
      end
    end

    def validate_order_direction
      params[:direction] = if SORT_DIRECTION.include? params[:direction]
        params[:direction]
      else
        "DESC"
      end
    end
end
