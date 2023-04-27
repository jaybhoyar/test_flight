# frozen_string_literal: true

require "test_helper"

class NoteTest < ActiveSupport::TestCase
  def setup
    @customer = create :user
    User.current = create :user, organization: @customer.organization
  end

  test "contact_id should not be blank" do
    note = Note.new(agent_id: @customer.id, description: "test")

    assert_not note.valid?
    assert_includes note.errors.full_messages, "User must exist"
  end

  test "agent_id should not be blank" do
    note = Note.new(description: "test", customer_id: @customer.id)

    assert_not note.valid?
    assert_includes note.errors.full_messages, "Agent must exist"
  end

  test "description should not be blank" do
    note = Note.new(agent_id: User.current.id, customer_id: @customer.id)

    assert_not note.valid?
    assert note.errors.added?(:description, "can't be blank")
  end

  test "should save for valid data" do
    note = Note.new(agent_id: User.current.id, description: "test", customer_id: @customer.id)

    assert note.valid?
    assert note.save
  end
end
