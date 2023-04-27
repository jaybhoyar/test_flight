# frozen_string_literal: true

require "test_helper"

class Desk::Companies::DeletionServiceTest < ActiveSupport::TestCase
  def setup
    @user = create(:user, company: @company)
    @organization = @user.organization

    @company_one = create(:company)
    @company_two = create(:company)
  end

  def test_delete_companies_success
    companies_deletion_service = Desk::Companies::DeletionService.new(companies).process

    assert_equal "Companies have been successfully deleted.", companies_deletion_service
  end

  def test_delete_company_success
    companies_deletion_service = Desk::Companies::DeletionService.new([@company_one]).process

    assert_equal "Company has been successfully deleted.", companies_deletion_service
  end

  private

    def companies
      Company.all
    end
end
