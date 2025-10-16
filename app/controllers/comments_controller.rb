class CommentsController < ApplicationController
  def create
    @todo = Todo.find(params[:todo_id])
    authorize_project!(@todo.project)

    comment = @todo.comments.new(comment_params.merge(author: current_user))
    if comment.save
      redirect_to @todo, notice: "Comment added."
    else
      redirect_to @todo, alert: "Comment failed."
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    project = comment.todo.project
    authorize_project!(project)
    comment.destroy
    redirect_to comment.todo, notice: "Comment removed."
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end

  def authorize_project!(project)
    redirect_to projects_path, alert: "Not allowed." unless project.owner_id == current_user.id
  end
end
