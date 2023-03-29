# frozen_string_literal: true

class Desk::Ticket::Comment::TwitterReplyService
  attr_reader :ticket, :comment

  def initialize(ticket, comment)
    @ticket = ticket
    @comment = comment
  end

  def process
    account = Desk::Twitter::Account.where(
      organization_id: ticket.organization_id,
      oauth_user_id: twitter_activity.for_user_id
    ).first

    options = if comment.channel_mode == "direct_message"
      send_direct_message(account)
    else
      send_tweet(account)
    end

    comment.update!(message_id: options[:id_str])
    Desk::Integrations::Twitter::ActivityService.new(ticket, options[:id_str], options).create_activity
  end

  def send_tweet(account)
    twitter_screen_name = comment.ticket.submitter.customer_detail.twitter_screen_name
    reply_message = "@#{twitter_screen_name} #{comment.info.to_plain_text}"
    reply_tweet = account.client.update(reply_message, in_reply_to_status_id:)
    options = reply_tweet.as_json.with_indifferent_access
    options.merge!(
      event_type: "tweet_create_events",
      for_user_id: options[:user][:id_str],
      user_twitter_id: options[:in_reply_to_user_id_str]
    )
    options
  end

  def send_direct_message(account)
    reply_content = comment.info.to_plain_text&.strip&.delete_prefix(
      "@#{ticker_requester_details.twitter_screen_name}"
    )&.strip

    reply_message = account.client.create_direct_message(ticker_requester_details.twitter_id, reply_content)
    options = reply_message.as_json.with_indifferent_access
    options.merge!(
      event_type: "direct_message_events",
      id_str: reply_message.id.to_s,
      for_user_id: reply_message.sender_id.to_s,
      user_twitter_id: reply_message.recipient_id.to_s
    )
    options
  end

  private

    def twitter_account
      @_twitter_account || ticket.twitter_account
    end

    def requester_comments
      ticket.comments.where(author: ticker_requester)
    end

    def twitter_activity
      parent_comment = requester_comments.last_comment

      if parent_comment
        Desk::Twitter::Activity.where(ticket_id: ticket.id, activity_id: parent_comment.message_id).first
      end
    end

    def in_reply_to_status_id
      parent_comment = requester_comments.where(channel_mode: comment.channel_mode).last_comment

      if parent_comment
        parent_comment.in_reply_to_id.nil? ? parent_comment.message_id : parent_comment.in_reply_to_id
      end
    end

    def ticker_requester
      @_ticker_requester ||= ticket.requester
    end

    def ticker_requester_details
      @_ticker_requester_details ||= ticker_requester.customer_detail
    end
end
