class NotificationService
  # Create a notification for a user
  def self.notify(recipient:, action:, notifiable:, actor: nil, metadata: {})
    return unless recipient.is_a?(User)
    return unless Notification::ACTIONS.value?(action)

    notification = Notification.create!(
      recipient: recipient,
      actor: actor,
      action: action,
      notifiable: notifiable,
      metadata: metadata.to_json
    )

    # Send notifications based on user preferences
    deliver_notifications(notification)

    notification
  end

  # Notify activity assignment
  def self.notify_activity_assigned(activity, actor)
    return unless activity.assignee && activity.assignee != actor

    notify(
      recipient: activity.assignee,
      action: "activity_assigned",
      notifiable: activity,
      actor: actor
    )
  end

  # Notify activity update
  def self.notify_activity_updated(activity, actor)
    recipients = [activity.assignee, activity.project.owner].compact.uniq - [actor]

    recipients.each do |recipient|
      notify(
        recipient: recipient,
        action: "activity_updated",
        notifiable: activity,
        actor: actor
      )
    end
  end

  # Notify comment added
  def self.notify_comment_added(comment)
    activity = comment.activity
    recipients = [activity.assignee, activity.project.owner].compact.uniq - [comment.author]

    recipients.each do |recipient|
      notify(
        recipient: recipient,
        action: "comment_added",
        notifiable: comment,
        actor: User.find(comment.author_id)
      )
    end
  end

  # Notify message received
  def self.notify_message_received(message)
    conversation = message.conversation
    recipients = conversation.users.where.not(id: message.user_id)

    recipients.each do |recipient|
      notify(
        recipient: recipient,
        action: "message_received",
        notifiable: message,
        actor: message.user
      )
    end
  end

  # Notify upcoming due date
  def self.notify_due_soon(activity, days_until_due)
    return unless activity.assignee

    notify(
      recipient: activity.assignee,
      action: "activity_due_soon",
      notifiable: activity,
      metadata: { days_until_due: days_until_due }
    )
  end

  # Notify overdue activity
  def self.notify_overdue(activity)
    return unless activity.assignee

    notify(
      recipient: activity.assignee,
      action: "activity_overdue",
      notifiable: activity
    )
  end

  private

  def self.deliver_notifications(notification)
    recipient = notification.recipient

    # Queue in-app notification (already created)

    # Queue email if enabled
    if recipient.email_notifications
      NotificationMailer.notification_email(notification).deliver_later
    end

    # Queue SMS if enabled
    if recipient.sms_notifications && recipient.phone_number.present?
      SmsNotificationJob.perform_later(notification.id)
    end
  end
end
