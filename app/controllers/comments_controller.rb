class CommentsController < ApplicationController
  def create
    @activity = Activity.find(params[:activity_id])
    return unless authorize_comment!(@activity, ability: :comment)

    parent_comment = params[:comment][:parent_id].present? ? @activity.comments.find_by(id: params[:comment][:parent_id]) : nil

    comment_attrs = comment_params.except(:parent_id).merge(author: current_user)
    comment = @activity.comments.new(comment_attrs)
    comment.parent = parent_comment if parent_comment.present?

    if comment.save
      # Send notification for new comment
      NotificationService.notify_comment_added(comment)

      redirect_to @activity, notice: (parent_comment ? "Reply added." : "Update added.")
    else
      redirect_to @activity, alert: (parent_comment ? "Reply failed." : "Update failed.")
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    project = comment.activity.project
    return unless authorize_comment!(comment.activity, ability: :destroy, comment: comment)

    comment.destroy
    redirect_to comment.activity, notice: "Update removed."
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id, files: [])
  end

  def authorize_comment!(activity, ability:, comment: nil)
    project = activity.project
    allowed = case ability
              when :comment
                can_comment_on_activity?(activity)
              when :destroy
                can_manage_project?(project) || comment&.author_id == current_user.id
              else
                false
              end

    return true if allowed

    redirect_to projects_path, alert: "Not allowed."
    false
  end
end
