# frozen_string_literal: true

class Desk::Outbound::MailService
  attr_reader :outbound_message, :rule, :test_email_recepient

  def initialize(outbound_message_id, test_email_recepient = nil)
    @outbound_message = ::Outbound::Message.find(outbound_message_id)
    @rule = @outbound_message.rule
    @test_email_recepient = test_email_recepient
  end

  def process
    case test_email_recepient.blank? && outbound_message.message_type
    when "ongoing"
      match_delivery_window_to_send_ongoing_messages
    when "broadcast"
      match_delivery_window_to_send_broadcast_messages
    else
      test_email_recepient.each do |email|
        OutboundMessageMailer
          .with(organization_name: outbound_message.organization.name)
          .test_outbound_message(outbound_message, email)
          .deliver
      end
    end
  end

  private

    def match_delivery_window_to_send_ongoing_messages
      if outbound_message.check_current_time_in_delivery_window?
        dispatch_outbound_email
        outbound_message.update!(state: "Live")
      end
    end

    def match_delivery_window_to_send_broadcast_messages
      if outbound_message.check_current_time_in_delivery_window?
        dispatch_outbound_email
        outbound_message.update!(state: "Sent")
        outbound_message.update!(waiting_for_delivery_window: false)
      end
    end

    def tweaked_email_subject(user)
      substitute_email_variables(outbound_message.email_subject, user)
    end

    def tweaked_email_content(user)
      substitute_email_variables(outbound_message.email_content.body&.to_html, user)
    end

    def substitute_email_variables(template_str, user)
      placeholders_vars = ::Placeholders::UserCarrier.new(user)

      template = Liquid::Template.parse(template_str)
      template.render(placeholders_vars.build)
    end

    def dispatch_outbound_email
      users = filter_users
      users.each do |user|
        if user.has_active_email_subscription?
          email_subject = tweaked_email_subject(user)
          email_content = tweaked_email_content(user)

          user.email_contact_details.each do |contact_detail|
            ::OutboundMessageMailer
              .with(organization_name: outbound_message.organization.name)
              .new_outbound_message(outbound_message, email_subject, email_content, contact_detail)
              .deliver
          end
        end
      end
    end

    def filter_users
      if rule.present?
        rule_users_finder = ::Desk::Core::RuleUsersFinder.new(rule)
        users = rule.conditions.exists? ? rule_users_finder.matching_users : rule_users_finder.base_query
      else
        users = outbound_message.organization
          .users
          .only_active
      end

      if outbound_message.ongoing?
        users = filter_notified_users(users)
        users = filter_future_users(users) if outbound_message.new_users_only?
      end

      users
    end

    def filter_future_users(users)
      users.where("users.created_at > ?", outbound_message.updated_at)
    end

    def filter_notified_users(users)
      message_received_user_ids = outbound_message.message_events
        .pluck(:user_id)
        .uniq

      users.where.not(id: message_received_user_ids)
    end
end
