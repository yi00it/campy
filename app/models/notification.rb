class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(recipient: user) }

  # Notification actions
  ACTIONS = {
    activity_assigned: "activity_assigned",
    activity_updated: "activity_updated",
    activity_due_soon: "activity_due_soon",
    activity_overdue: "activity_overdue",
    comment_added: "comment_added",
    comment_mentioned: "comment_mentioned",
    message_received: "message_received",
    project_invitation: "project_invitation",
    member_joined: "member_joined"
  }.freeze

  validates :action, inclusion: { in: ACTIONS.values }

  # Mark notification as read
  def mark_as_read!
    update(read_at: Time.current) unless read?
  end

  # Mark notification as unread
  def mark_as_unread!
    update(read_at: nil) if read?
  end

  def read?
    read_at.present?
  end

  # Get notification message for display
  def message
    case action
    when "activity_assigned"
      "#{actor_name} assigned you to #{notifiable.title}"
    when "activity_updated"
      "#{actor_name} updated #{notifiable.title}"
    when "activity_due_soon"
      "#{notifiable.title} is due in #{days_until_due} days"
    when "activity_overdue"
      "#{notifiable.title} is overdue"
    when "comment_added"
      "#{actor_name} commented on #{notifiable.activity.title}"
    when "comment_mentioned"
      "#{actor_name} mentioned you in a comment"
    when "message_received"
      "#{actor_name} sent you a message"
    when "project_invitation"
      "#{actor_name} invited you to join #{notifiable.name}"
    when "member_joined"
      "#{actor_name} joined #{notifiable.name}"
    else
      "New notification"
    end
  end

  # Get URL for notification
  def url
    case notifiable_type
    when "Activity"
      Rails.application.routes.url_helpers.activity_path(notifiable)
    when "Comment"
      Rails.application.routes.url_helpers.activity_path(notifiable.activity)
    when "Message"
      Rails.application.routes.url_helpers.conversation_path(notifiable.conversation)
    when "Project"
      Rails.application.routes.url_helpers.project_path(notifiable)
    else
      Rails.application.routes.url_helpers.root_path
    end
  end

  private

  def actor_name
    actor&.display_name || "Someone"
  end

  def days_until_due
    return 0 unless notifiable.respond_to?(:due_on)
    (notifiable.due_on - Date.current).to_i
  end
end
