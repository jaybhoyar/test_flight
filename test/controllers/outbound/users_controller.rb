# frozen_string_literal: true

class Outbound::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_outbound_message, only: [:download]

  def download
    if @outbound_message && @outbound_message.rule
      notified_recipients = @outbound_message.notified_recipients

      respond_to do |format|
        format.csv do
          send_data Desk::Outbound::MatchingUsers::GenerateCsv.new(notified_recipients).process,
            filename: downloaded_recipients_file_name
        end
      end
    end
  end

  private

    def load_outbound_message
      @outbound_message = Outbound::Message.find(params[:outbound_id])
    end

    def downloaded_recipients_file_name
      current_date_time = DateTime.now.strftime("%d-%m-%Y-%I.%M%p")
      "#{@outbound_message.title}-campaign-recipients-#{current_date_time}.csv"
    end
end
