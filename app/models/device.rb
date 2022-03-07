# frozen_string_literal: true

class Device < ::ApplicationRecord
  belongs_to :user

  validates_presence_of :platform
  validates :device_token, presence: true, uniqueness: true
end
