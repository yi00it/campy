class SmsNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = Notification.find(notification_id)
    recipient = notification.recipient

    return unless recipient.sms_notifications && recipient.phone_number.present?

    # Send SMS via Twilio (requires twilio-ruby gem)
    # Uncomment and configure when Twilio is set up:
    #
    # client = Twilio::REST::Client.new(
    #   ENV['TWILIO_ACCOUNT_SID'],
    #   ENV['TWILIO_AUTH_TOKEN']
    # )
    #
    # client.messages.create(
    #   from: ENV['TWILIO_PHONE_NUMBER'],
    #   to: recipient.phone_number,
    #   body: sms_message(notification)
    # )

    Rails.logger.info "SMS would be sent to #{recipient.phone_number}: #{sms_message(notification)}"
  end

  private

  def sms_message(notification)
    # Keep SMS messages short (160 chars)
    case notification.action
    when "activity_assigned"
      "New task: #{notification.notifiable.title.truncate(100)}"
    when "activity_due_soon"
      "Reminder: #{notification.notifiable.title.truncate(90)} due soon"
    when "activity_overdue"
      "Overdue: #{notification.notifiable.title.truncate(100)}"
    when "message_received"
      "New message from #{notification.actor&.display_name}"
    else
      "New notification from Campy"
    end
  end
end
