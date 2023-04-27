# frozen_string_literal: true

require "test_helper"

class RoundRobinAgentSlotTest < ActiveSupport::TestCase
  def test_that_slot_is_valid
    slot = build :round_robin_agent_slot
    assert slot.valid?
  end

  def test_that_slot_is_valid_without_group
    slot = build :round_robin_agent_slot, group: nil
    assert slot.valid?
  end
end
