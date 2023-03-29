# frozen_string_literal: true

require "set"

class Desk::Customers::MergeService
  attr_accessor :primary_customer, :secondary_customer_ids, :organization, :errors, :response

  def initialize(primary_customer, secondary_customer_ids, organization)
    @primary_customer = primary_customer
    @secondary_customer_ids = secondary_customer_ids
    @organization = organization
    @primary_tags = Set.new
    @deletion_list = Set.new
    @updation_list = Set.new
    @errors = []
  end

  def process
    User.transaction do
      find_or_create_primary_customer_detail
      get_primary_customer_tags
      process_secondary_customers

      raise ActiveRecord::Rollback if errors.present?
    end
  end

  def response
    if errors.empty?
      { json: { notice: "Customers have been successfully merged." }, status: :ok }
    else
      { json: { notice: "Error while merging customers" }, status: :unprocessable_entity }
    end
  end

  private

    def find_or_create_primary_customer_detail
      return if primary_customer.customer_detail

      primary_customer.create_customer_detail
    end

    def get_primary_customer_tags
      primary_customer.customer_detail.tags.each do |tag|
        @primary_tags << tag.name
      end
    end

    def process_secondary_customer_tags(secondary_customer)
      if secondary_customer && secondary_customer.customer_detail
        Tagging.where(taggable_id: secondary_customer.customer_detail.id).each do |tagging|
          if @primary_tags.add?(tagging.tag.name).nil?
            @deletion_list.add(tagging.id)
          else
            @updation_list.add(tagging.id)
          end
        end
      end
    end

    def update_customer_taggings
      unless Tagging.where(id: @updation_list).update_all(taggable_id: primary_customer.customer_detail.id)
        errors << "Error updating customer taggings"
      end
    end

    def delete_customer_taggings
      unless Tagging.where(id: @deletion_list).destroy_all
        errors << "Error deleting customer taggings"
      end
    end

    def process_secondary_customers
      @secondary_customer_ids.each do |secondary_customer_id|

        secondary_customer = @organization.customers.find_by(id: secondary_customer_id)

        update_ticket_creator(secondary_customer)
        update_ticket_submitter(secondary_customer)
        update_customer_notes(secondary_customer)
        update_ticket_comments(secondary_customer)
        migrate_customer_email_contacts(secondary_customer)
        migrate_customer_phone_contacts(secondary_customer)
        migrate_customer_link_contacts(secondary_customer)
        process_secondary_customer_tags(secondary_customer)
        update_customer_taggings
        delete_customer_taggings
        remove_ticket_colliders(secondary_customer)
        update_ticket_followers(secondary_customer)
        delete_secondary_customer_details(secondary_customer)
        delete_secondary_customer(secondary_customer)
      end
    end

    def update_ticket_creator(secondary_customer)
      unless secondary_customer.tickets.update_all(requester_id: @primary_customer.id)
        errors << "Error updating ticket creator"
      end
    end

    def update_ticket_submitter(secondary_customer)
      unless Ticket.where(submitter_id: secondary_customer.id).update_all(submitter_id: @primary_customer.id)
        errors << "Error updating ticket submitter"
      end
    end

    def update_customer_notes(secondary_customer)
      unless secondary_customer.notes.update_all(customer_id: @primary_customer.id)
        errors << "Error updating customer notes"
      end
    end

    def update_ticket_comments(secondary_customer)
      unless Comment.where(author_id: secondary_customer.id).update_all(author_id: @primary_customer.id)
        errors << "Error updating ticket comments"
      end
    end

    def migrate_customer_email_contacts(secondary_customer)
      unless secondary_customer.email_contact_details.update_all(user_id: @primary_customer.id)
        errors << "Error migrating customer email contacts"
      end
    end

    def migrate_customer_phone_contacts(secondary_customer)
      unless secondary_customer.phone_contact_details.update_all(user_id: @primary_customer.id)
        errors << "Error migrating customer phone contacts"
      end
    end

    def migrate_customer_link_contacts(secondary_customer)
      unless secondary_customer.link_contact_details.update_all(user_id: @primary_customer.id)
        errors << "Error migrating customer phone contacts"
      end
    end

    def remove_ticket_colliders(secondary_customer)
      unless Desk::Ticket::Collider
          .where(user_id: secondary_customer.id)
          .destroy_all

        errors << "Error deleting ticket collider"
      end
    end

    def update_ticket_followers(secondary_customer)
      unless Desk::Ticket::Follower
          .where(user_id: secondary_customer.id)
          .update_all(user_id: @primary_customer.id)

        errors << "Error updating  ticket followers"
      end
    end

    def delete_secondary_customer_details(secondary_customer)
      unless secondary_customer.customer_detail.nil?
        unless secondary_customer.customer_detail.destroy
          errors << "Error deleting customer details"
        end
      end
    end

    def delete_secondary_customer(secondary_customer)
      unless secondary_customer.reload.destroy
        errors << "Error deleting customer"
      end
    end
end
