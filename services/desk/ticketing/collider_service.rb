# frozen_string_literal: true

module Desk::Ticketing
  class ColliderService
    attr_accessor :ticket, :user

    def initialize(ticket, user)
      @ticket = ticket
      @user = user
    end

    def mark(kind = :view)
      ticket.transaction do
        collider = find_or_initialize
        collider.update(kind:)
      end
    end

    def clear
      ticket.ticket_colliders.where(user_id: user.id).destroy_all
    end

    private

      def find_or_initialize
        ticket.ticket_colliders.find_or_initialize_by(user_id: user.id)
      end
  end
end
