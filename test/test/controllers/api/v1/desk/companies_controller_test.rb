# frozen_string_literal: true

require "test_helper"

class Api::V1::Desk::CompaniesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create :user
    @customer = create(:user)
    @organization = @user.organization
    @company = create(:company, organization: @organization, name: "WayneCorp")

    @customer.update(role: nil, company: @company)
    Thread.current[:organization] = @organization

    sign_in(@user)

    host! test_domain(@organization.subdomain)
    @manage_permission = Permission.find_or_create_by(name: "admin.manage_companies", category: "Admin")
    role = create :organization_role, permissions: [@manage_permission]
    @user.update(role:)

    @ticket = create(:ticket, organization: @organization, requester: @customer, subject: "Meri marzi")
  end

  def test_index_success_with_pagination
    ["AceInvoice", "NeetoDesk", "Spinkart", "AceKart"].each do |name|
      create(:company, name:, organization: @organization)
    end

    company_params = {
      company: {
        page_index: 1,
        page_size: 2
      }
    }

    get api_v1_desk_companies_url, params: company_params, headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["companies"].count
    assert_equal "AceInvoice", json_body["companies"][0]["name"]
    assert_equal "AceKart", json_body["companies"][1]["name"]

    company_params = {
      company: {
        page_index: 2,
        page_size: 2
      }
    }

    get api_v1_desk_companies_url, params: company_params, headers: headers(@user)

    assert_response :ok
    assert_equal 2, json_body["companies"].count
    assert_equal "NeetoDesk", json_body["companies"][0]["name"]
    assert_equal "Spinkart", json_body["companies"][1]["name"]

    company_params = {
      company: {
        page_index: 3,
        page_size: 2
      }
    }

    get api_v1_desk_companies_url, params: company_params, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["companies"].count
    assert_equal "WayneCorp", json_body["companies"][0]["name"]
  end

  def test_index_success_with_search
    ["AceInvoice", "NeetoDesk", "Spinkart", "AceKart"].each do |name|
      create(:company, name:, organization: @organization)
    end

    company_params = {
      company: {
        search_term: "aceinvoice"
      }
    }

    get api_v1_desk_companies_url, params: company_params, headers: headers(@user)

    assert_response :ok
    assert_equal 1, json_body["companies"].count
    assert_equal "AceInvoice", json_body["companies"][0]["name"]
  end

  def test_index_with_sorted_names
    ["AceInvoice", "NeetoDesk"].each do |name|
      create(:company, name:, organization: @organization)
    end
    get api_v1_desk_companies_url, params: { company: { name: "NeetoDesk" } }, headers: headers(@user)
    companies = @organization.companies.order(:name)

    assert_response :ok
    assert_equal companies.count, json_body["companies"].count
    assert_equal companies[0].id, json_body["companies"][0]["id"]
  end

  def test_index_with_sort_by
    ["AceInvoice", "NeetoDesk"].each do |name|
      create(:company, name:, organization: @organization)
    end
    get api_v1_desk_companies_url, params: { company: { column: "name", direction: "desc" } },
      headers: headers(@user)

    assert_response :ok
    assert_equal "WayneCorp", json_body["companies"][0]["name"]
    assert_equal "NeetoDesk", json_body["companies"][1]["name"]
    assert_equal "AceInvoice", json_body["companies"][2]["name"]
  end

  def test_that_company_is_created
    company_params = {
      company: {
        name: "Stark Industries",
        description: "We make Iron man suits",
        notes: "Defense Contractor of S.H.I.E.L.D"
      }
    }

    assert_difference "Company.count" do
      post api_v1_desk_companies_url(company_params), headers: headers(@user)
    end

    assert_response :ok
  end

  def test_that_create_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    company_params = {
      company: {
        name: "Stark Industries",
        description: "We make Iron man suits",
        notes: "Defense Contractor of S.H.I.E.L.D"
      }
    }

    post api_v1_desk_companies_url(company_params), headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_company_is_not_created_without_name
    company_params = {
      company: {
        name: "",
        description: "The Dark Knight Rises"
      }
    }

    assert_no_difference "Company.count" do
      post api_v1_desk_companies_url(company_params), headers: headers(@user)
    end
    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name can't be blank"
  end

  def test_that_company_is_not_created_with_duplicate_name
    company_params = {
      company: {
        name: @company.name,
        description: "The Dark Knight Rises"
      }
    }

    assert_no_difference "@organization.companies.count" do
      post api_v1_desk_companies_url(company_params), headers: headers(@user)
    end

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name has already been taken"
  end

  def test_that_company_is_updated
    company_params = {
      company: {
        name: "Stark Industries",
        description: "We Make Iron Man Suits"
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :ok
    assert_includes json_body["notice"], "Company has been successfully updated."

    @company.reload
    assert_equal "Stark Industries", @company.name
    assert_equal "We Make Iron Man Suits", @company.description
  end

  def test_that_update_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    company_params = {
      company: {
        name: "Stark Industries",
        description: "We Make Iron Man Suits"
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :forbidden
  end

  def test_that_company_is_not_updated_without_name
    company_params = {
      company: {
        name: "",
        description: "We Make Iron Man Suits"
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Name can't be blank"
  end

  def test_that_company_is_created_with_company_domain
    company_params = {
      company: {
        name: "Stark Industries",
        description: "We make Iron Man suits",
        company_domains_attributes: [{ name: "marvel.com" }]
      }
    }

    post api_v1_desk_companies_url(company_params), headers: headers(@user)

    assert_response :ok
    assert_equal "marvel.com", Company.all.order("name DESC").last.company_domains.first.name
  end

  def test_that_company_is_not_created_with_empty_company_domain_name
    company_params = {
      company: {
        name: "Wayne Corp",
        description: "The Dark Knight Rises",
        company_domains_attributes: [{ name: "" }]
      }
    }

    post api_v1_desk_companies_url(company_params), headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Company domains name can't be blank"
  end

  def test_that_company_domain_is_updated
    company_domain = create(:company_domain, company: @company)

    company_params = {
      company: {
        name: "Stark Industries",
        description: "We Make Iron Man Suits",
        company_domains_attributes: [{ name: "marvel.com", id: company_domain.id }]
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :ok
    assert_includes json_body["notice"], "Company has been successfully updated."

    @company.reload
    assert_equal "marvel.com", Company.all.order("name DESC").last.company_domains.first.name
  end

  def test_that_company_domain_is_not_updated_with_empty_name
    company_domain = create(:company_domain, company: @company)

    company_params = {
      company: {
        name: "Stark Industries",
        description: "We Make Iron Man Suits",
        company_domains_attributes: [{ name: "", id: company_domain.id }]
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Company domains name can't be blank"
  end

  def test_that_company_domain_is_not_updated_with_duplicate_name
    company_domain_one = create(:company_domain, company: @company)
    company_domain_two = create(:company_domain, name: "Stark.com", company: @company)

    company_params = {
      company: {
        name: "Stark Industries",
        description: "We Make Iron Man Suits",
        company_domains_attributes: [{ name: company_domain_two.name }]
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :unprocessable_entity
    assert_includes json_body["errors"], "Domain Stark.com is already taken"
  end

  def test_that_company_domain_is_deleted
    company_domain = create(:company_domain, company: @company)

    company_params = {
      company: {
        name: "Stark Industries",
        description: "We Make Iron Man Suits",
        company_domains_attributes: [{ name: company_domain.name, id: company_domain.id, _destroy: "1" }]
      }
    }

    assert_difference "@company.company_domains.count", -1 do
     patch api_v1_desk_company_url(@company),
       params: company_params,
       headers: headers(@user)
   end
  end

  def test_that_company_is_added_to_existing_customer_if_opted
    customer = create(:user, role: nil, email: "tony@marvel.com", organization: @organization)

    company_params = {
      company: {
        name: "Stark Industries",
        add_company_to_existing_customers: true,
        company_domains_attributes: [{ name: "marvel.com" }]
      }
    }

    patch api_v1_desk_company_url(@company),
      params: company_params,
      headers: headers(@user)

    assert_response :ok
    customer.reload
    assert_equal customer.company_id, CompanyDomain.where(name: "marvel.com").first.company.id
  end

  def test_that_company_is_not_added_to_existing_customer_if_not_opted
    customer = create(:user, role: nil, email: "tony@marvel.com", organization: @organization)

    company_params = {
      company: {
        name: "Stark Industries",
        add_company_to_existing_customers: false,
        company_domains_attributes: [{ name: "marvel.com" }]
      }
    }

    post api_v1_desk_companies_url(company_params), headers: headers(@user)

    assert_response :ok
    customer.reload
    assert_nil customer.company_id
  end

  def test_companies_deletion
    user = create(:user, role: nil, company: @company)

    company_params = {
      company: {
        ids: [@company.id]
      }
    }

    assert_difference "Company.count", -1 do
      delete destroy_multiple_api_v1_desk_companies_url(company_params), headers: headers(@user)
    end

    assert_response :ok
  end

  def test_that_destroy_doesnt_work_without_permissions
    role = create :organization_role
    @user.update(role:)

    user = create(:user, role: nil, company: @company)

    company_params = {
      company: {
        ids: [@company.id]
      }
    }

    delete destroy_multiple_api_v1_desk_companies_url(company_params), headers: headers(@user)

    assert_response :forbidden
  end

  def test_show_success
    get api_v1_desk_company_url(@company.id), headers: headers(@user)

    assert_response :ok
    assert_equal ["id", "name", "description", "company_domains_attributes", "customers", "tickets"],
      json_body["company"].keys
  end

  def test_that_company_is_deleted
    assert_difference "Company.count", -1 do
      delete api_v1_desk_company_path(@company), headers: headers(@user)
    end

    assert_equal 1, Ticket.count
    assert_response :ok
    assert_includes json_body["notice"], "Company has been successfully deleted."
  end
end
