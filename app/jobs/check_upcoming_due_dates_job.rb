class CheckUpcomingDueDatesJob < ApplicationJob
  queue_as :default

  def perform
    # Check for activities due in 1, 3, and 7 days
    [1, 3, 7].each do |days|
      due_date = Date.current + days.days

      Activity.where(due_on: due_date, is_done: false)
              .where.not(assignee_id: nil)
              .find_each do |activity|
        # Only notify if not already notified today
        unless already_notified_today?(activity, days)
          NotificationService.notify_due_soon(activity, days)
        end
      end
    end

    # Check for overdue activities
    Activity.where("due_on < ?", Date.current)
            .where(is_done: false)
            .where.not(assignee_id: nil)
            .find_each do |activity|
      unless already_notified_today_overdue?(activity)
        NotificationService.notify_overdue(activity)
      end
    end
  end

  private

  def already_notified_today?(activity, days)
    Notification.where(
      notifiable: activity,
      action: "activity_due_soon",
      created_at: Date.current.beginning_of_day..Date.current.end_of_day
    ).exists?
  end

  def already_notified_today_overdue?(activity)
    Notification.where(
      notifiable: activity,
      action: "activity_overdue",
      created_at: Date.current.beginning_of_day..Date.current.end_of_day
    ).exists?
  end
end
