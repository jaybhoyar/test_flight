# frozen_string_literal: true

module Search
  class User < Base
    include UserQueryHelper

    def scope
      ::User.where(organization:)
    end

    def predicate
      full_name.matches("%#{value}%")
        .or(
          users[:email].lower.matches("%#{value}%")
        )
    end
  end
end
