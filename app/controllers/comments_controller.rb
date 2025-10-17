class CommentsController < ApplicationController
  def create
    @activity = Activity.find(params[:activity_id])
    return unless authorize_project!(@activity.project)

    update = @activity.comments.new(comment_params.merge(author: current_user))
    if update.save
      redirect_to @activity, notice: "Update added."
    else
      redirect_to @activity, alert: "Update failed."
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
    params.require(:comment).permit(:body, files: [])
  end

  def authorize_project!(project)
    return true if project.owner_id == current_user.id

    redirect_to projects_path, alert: "Not allowed."
    false
  end
end
