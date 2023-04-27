# frozen_string_literal: true

FactoryBot.define do
  factory :group_record_visibility do
    record_visibility { create :desk_record_visibility }
    group { create :group }
  end
end
