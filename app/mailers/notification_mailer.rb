class NotificationMailer < ApplicationMailer
  def notification_email(notification)
    @notification = notification
    @recipient = notification.recipient
    @actor = notification.actor
    @notifiable = notification.notifiable

    mail(
      to: @recipient.email,
      subject: notification_subject(notification)
    )
  end

  def daily_digest(user, notifications)
    @user = user
    @notifications = notifications
    @unread_count = notifications.count

    # Group notifications by type
    @activity_notifications = notifications.where(action: ["activity_assigned", "activity_updated", "activity_due_soon", "activity_overdue"])
    @comment_notifications = notifications.where(action: ["comment_added", "comment_mentioned"])
    @message_notifications = notifications.where(action: "message_received")
    @project_notifications = notifications.where(action: ["project_invitation", "member_joined"])

    mail(
      to: @user.email,
      subject: "Your daily digest - #{@unread_count} new #{'notification'.pluralize(@unread_count)}"
    )
  end

  private

  def notification_subject(notification)
    case notification.action
    when "activity_assigned"
      "You've been assigned to: #{notification.notifiable.title}"
    when "activity_updated"
      "Activity updated: #{notification.notifiable.title}"
    when "activity_due_soon"
      "Reminder: #{notification.notifiable.title} is due soon"
    when "activity_overdue"
      "Overdue: #{notification.notifiable.title}"
    when "comment_added"
      "New comment on: #{notification.notifiable.activity.title}"
    when "comment_mentioned"
      "You were mentioned in a comment"
    when "message_received"
      "New message from #{notification.actor&.display_name}"
    when "project_invitation"
      "You've been invited to join #{notification.notifiable.name}"
    when "member_joined"
      "#{notification.actor&.display_name} joined #{notification.notifiable.name}"
    else
      "New notification"
    end
  end
end
