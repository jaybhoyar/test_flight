# frozen_string_literal: true

class Desk::Customers::FilterService
  attr_reader :customers, :options, :count

  def initialize(customers, options)
    @customers = customers
    @options = options
  end

  def process
    filter_by_tag
    filter_by_status
    filter_by_company

    @count = customers.count

    paginate

    customers
  end

  def total_count
    count
  end

  private

    def paginate
      page_index = options.dig(:customer, :page_index)
      return if page_index.blank?

      page_size = options.dig(:customer, :page_size)

      @customers = customers.page(page_index).per(page_size)
    end

    def filter_by_tag
      tag_id = options.dig(:customer, :filters, :tag_id)
      return if tag_id.blank?

      @customers = customers.joins(customer_detail: :taggings).where("taggings.tag_id = ?", tag_id)
    end

    def filter_by_company
      company_ids = options.dig(:customer, :filters, :company_ids)
      return if company_ids.blank?

      @customers = customers.where(company_id: company_ids)
    end

    def filter_by_status
      status = options.dig(:customer, :filters, :status)
      return if status.blank?

      @customers = if status.eql? "blocked"
        customers.where.not(blocked_at: nil)
      else
        customers.where(blocked_at: nil)
      end
    end
end
