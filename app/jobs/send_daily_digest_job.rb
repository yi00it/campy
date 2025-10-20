class SendDailyDigestJob < ApplicationJob
  queue_as :default

  def perform
    # Find all users who want daily digests
    User.where(daily_digest: true, email_notifications: true).find_each do |user|
      # Get unread notifications from the last 24 hours
      notifications = user.notifications
                          .unread
                          .where("created_at >= ?", 24.hours.ago)
                          .recent

      # Only send if there are notifications
      if notifications.any?
        NotificationMailer.daily_digest(user, notifications).deliver_now
      end
    end
  end
end
