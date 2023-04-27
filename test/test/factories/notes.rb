# frozen_string_literal: true

FactoryBot.define do

  factory :note do
    association :user
    description { "There is some urgent issue with AceInvoice. So please contact with the client." }
  end

end
