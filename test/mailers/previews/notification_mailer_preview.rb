# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/notification_email
  def notification_email
    NotificationMailer.notification_email
  end

  # Preview this email at http://localhost:3000/rails/mailers/notification_mailer/daily_digest
  def daily_digest
    NotificationMailer.daily_digest
  end
end
