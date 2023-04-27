# frozen_string_literal: true

require "test_helper"

class EmailContactDetailTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @user2 = create(:user)
  end

  test "create success of email as a contact detail with valid params" do
    valid_email = "matt@spinkart.com"
    email = EmailContactDetail.new(value: valid_email, user_id: @user.id)
    assert email.valid?
  end

  test "create failure of email as a contact detail with invalid params" do
    invalid_email = "12.com"
    email = EmailContactDetail.new(value: invalid_email, user_id: @user.id)
    assert_not email.valid?
    assert_equal ["is invalid"], email.errors[:value]
  end

  test "create email contact details with valid primary status" do
    EmailContactDetail.create!(
      value: "matt@spinkart.ca",
      user_id: @user.id,
      primary: false)
    EmailContactDetail.create!(
      value: "matt@spinkart.us",
      user_id: @user.id,
      primary: false)

    assert_equal 3, @user.email_contact_details.count
  end

  test "invalid email if email exists" do
    EmailContactDetail.create!(
      value: "oliver@spinkart.com",
      user_id: @user.id)

    duplicate_email = @user2.email_contact_details.first.value,
    email = EmailContactDetail.new(
      value: "oliver@spinkart.com",
      user_id: @user.id)

    assert_not email.valid?
    assert_equal "Email oliver@spinkart.com already exists.", email.errors.full_messages[0]
  end

  test "primary email must exist" do
    primary_email_contact = @user.email_contact_details.where(primary: true).first
    primary_email_contact.update(primary: false)

    assert_equal ["email must exist."], primary_email_contact.errors[:primary]
    assert primary_email_contact.reload.primary
  end

  test "create new primary email" do
    assert_equal 1, @user.reload.email_contact_details.where(primary: true).count

    primary_email = EmailContactDetail.create!(
      value: "oliver@spinkart.com",
      user_id: @user.id,
      primary: true)

    assert primary_email.primary?

    @user.reload

    assert_equal primary_email.value, @user.email
    assert_equal 2, @user.email_contact_details.count
    assert_equal 1, @user.email_contact_details.where(primary: true).count
  end

  test "zero primary email does not update email contact details" do
    primary_email = @user.email_contact_details.first
    primary_email.update(value: "oliver@example.com", primary: false)

    assert_not primary_email.valid?
    assert_equal ["email must exist."], primary_email.errors[:primary]
    assert primary_email.reload.primary?
  end

  test "duplicate primary email does not create email contact details" do
    user = create(:user, email: "oliver@spinkart.com")

    primary_email = user.email_contact_details.first
    email = EmailContactDetail.create(
      value: "oliver@spinkart.com",
      user_id: user.id,
      primary: true
    )

    assert_equal primary_email.value, user.reload.email
    assert_equal 1, user.email_contact_details.count
    assert_equal 1, user.email_contact_details.where(primary: true).count
    assert_nil email.id
  end

  ##
  # @FIXME:
  #     =>  There is a validation where we are not allowing new email to be created.
  #         Above test (Line: 91) take care of that; is this test still needed?
  #
  # test "duplicate primary email does not update email contact details" do
  #   user = create(:user, email: "oliver@spinkart.com")

  #   primary_email = user.email_contact_details.first
  #   email = EmailContactDetail.create(
  #     value: "oliver@spinkart.com",
  #     user_id: user.id,
  #     primary: false
  #   )

  #   assert email.valid?

  #   email.update(primary: true)

  #   assert_equal primary_email.value, user.reload.email
  #   assert_equal 2, user.email_contact_details.count
  #   assert_equal 1, user.email_contact_details.where(primary: true).count
  #   assert_not email.reload.primary?
  # end
end
