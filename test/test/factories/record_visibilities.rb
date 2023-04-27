# frozen_string_literal: true

FactoryBot.define do
  factory :record_visibility do
    visibility { "myself" }
    creator { create :user }
    record { create :desk_macro_rule }
    groups { create_list :group, 2 }
  end

  factory :desk_record_visibility, class: RecordVisibility do
    visibility { "myself" }
    creator { create :user }
    record { create :desk_macro_rule }
    groups { create_list :group, 2 }
  end
end
