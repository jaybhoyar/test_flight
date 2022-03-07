# frozen_string_literal: true
module TestFlight
  class Device < ActiveRecord::Base
    belongs_to :user

    validates_presence_of :platform
    validates :device_token, presence: true, uniqueness: true
  end
end
