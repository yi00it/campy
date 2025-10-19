class CommentsController < ApplicationController
  def create
    @activity = Activity.find(params[:activity_id])
    return unless authorize_project!(@activity.project)

    parent_comment = params[:comment][:parent_id].present? ? @activity.comments.find_by(id: params[:comment][:parent_id]) : nil

    comment_attrs = comment_params.except(:parent_id).merge(author: current_user)
    comment = @activity.comments.new(comment_attrs)
    comment.parent = parent_comment if parent_comment.present?

    if comment.save
      redirect_to @activity, notice: (parent_comment ? "Reply added." : "Update added.")
    else
      redirect_to @activity, alert: (parent_comment ? "Reply failed." : "Update failed.")
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    project = comment.activity.project
    return unless authorize_project!(project)

    comment.destroy
    redirect_to comment.activity, notice: "Update removed."
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :parent_id, files: [])
  end

  def authorize_project!(project)
    return true if project.accessible_by?(current_user)

    redirect_to projects_path, alert: "Not allowed."
    false
  end
end
