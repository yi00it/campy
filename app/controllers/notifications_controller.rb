class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications
                                 .recent
                                 .includes(:actor, :notifiable)
                                 .limit(50)

    calculate_notification_counts

    respond_to do |format|
      format.html # Full page
      format.turbo_stream { render partial: "dropdown", locals: { notifications: @notifications } }
    end
  end

  def dropdown
    @notifications = current_user.notifications
                                 .recent
                                 .includes(:actor, :notifiable)
                                 .limit(20)

    calculate_notification_counts

    render partial: "dropdown"
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_to notification.url }
      format.turbo_stream
      format.json { head :ok }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read" }
      format.turbo_stream
      format.json { head :ok }
    end
  end

  def unread_count
    count = current_user.notifications.unread.count

    respond_to do |format|
      format.json { render json: { count: count } }
    end
  end

  private

  def calculate_notification_counts
    all_notifications = current_user.notifications.unread

    @unread_count = all_notifications.count
    @mention_count = all_notifications.where(action: "comment_mentioned").count
    @activity_count = all_notifications.where(action: ["activity_assigned", "activity_updated", "activity_due_soon", "activity_overdue"]).count
    @project_count = all_notifications.where(action: ["project_invitation", "member_joined"]).count
  end
end
