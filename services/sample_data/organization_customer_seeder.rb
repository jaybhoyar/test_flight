# frozen_string_literal: true

module SampleData
  class OrganizationCustomerSeeder
    attr_reader :organization

    def initialize(organization)
      @organization = organization
    end

    def seed_customers
      tags = customer_tags.map { |tag| create_tag!(tag) }
      customers.map do |customer|
        # Assigns random number of random tags to each customer
        tags_last_index = tags.count - 1
        lower_limit = rand(0..tags_last_index)

        create_customer!(customer, tags[lower_limit..tags_last_index])
      end
    end

    private

      def create_tag!(customer_tag)
        Desk::Tag::CustomerTag.create!(customer_tag)
      end

      def companies
        @_companies ||= ["AceInvoice", "NeetoDesk"].map { |name| create_company!(name) }
      end

      def create_company!(name)
        Company.create!(
          name:,
          description: "About #{name}",
          company_domains_attributes: [
            { name: "#{name.downcase}.com" },
            { name: "#{name.downcase}.in" }
          ],
          organization:
        )
      end

      def create_customer!(customer_details, selected_tags)
        email = customer_details[:name].delete(" ").downcase + "@example.com"

        # user = User.find_by(email: email)
        customer = User.create!(
          organization_id: organization.id,
          email:,
          role: nil,
          password: "welcome",
          name: customer_details[:name],
          company: companies.sample)

        create_email_contact_details!(customer_details[:name], customer)

        customer.create_customer_detail!(
          language: "English",
          time_zone: "Kolkata",
          about: "About Me",
          tags: selected_tags)

        customer
      end

      def create_email_contact_details!(name, customer)
        username = name.delete(" ").downcase
        ["#{username}@example.us", "#{username}@example.ca"].map do |email|
          EmailContactDetail.create!(value: email, user: customer)
        end
      end

      def customers
        [
          {
            name: "Steph Stevenson"
          },
          {
            name: "Steve McFarland"
          },
          {
            name: "Jon Peters"
          }
        ]
      end

      def customer_tags
        [
          {
            name: "VIP",
            organization: @organization
          },
          {
            name: "Member",
            organization: @organization
          },
          {
            name: "Guest",
            organization: @organization
          },
          {
            name: "Inactive",
            organization: @organization
          }
        ]
      end

      def parameterize_organization_name
        @_parameterize_organization_name ||= organization.name.parameterize.underscore
      end
  end
end
