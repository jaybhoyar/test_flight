# frozen_string_literal: true

module SampleData
  class PrefixGenerator
    ORGANIZATIONS = ["app"]
    MODELS = {
      "Company": [[:name, "[UN] "]],
      "Ticket": [[:subject, "[UN] "]],
      "User": [[:first_name, "Un"], [:email, "un"]],
      "Desk::Core::Rule": [[:name, "[UN] "]],
      "Outbound::Message": [[:title, "[UN] "]],
      "View": [[:title, "[UN] "]],
      "Tag": [[:name, "[UN] "]],
      "Group": [[:name, "[UN] "]],
      "Desk::BusinessHour": [[:name, "[UN] "]],
      "Desk::CustomerSatisfaction::Survey": [[:name, "[UN] "]],
      "Desk::Tag::CustomerTag": [[:name, "[UN] "]],
      "Desk::Ticket::Field": [[:agent_label, "[UN] "]]
    }

    def run!
      MODELS.each_pair do |model, name_prefix_arr|
        name_prefix_arr.each do |name_prefix|
          name, prefix = name_prefix
          model.to_s.constantize.class_eval do
            before_create do |record|
              value = record.send(name)
              if ORGANIZATIONS.include?(record.organization.subdomain)
                record.send("#{name}=", "#{prefix}#{value}")
              end
            end
          end
        end
      end
    end
  end
end
